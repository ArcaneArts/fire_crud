// lib/gen/model_crud_parser_builder.dart
import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:toxic/extensions/string.dart';

class _FieldInfo {
  const _FieldInfo(this.name, this.type, this.importUri, this.dartType);

  final String name; // e.g. "title"
  final String type; // e.g. "String?"
  final Uri importUri;
  final DartType dartType;
}

List<_FieldInfo> _fieldsOf(ClassElement cls) {
  final LibraryElement owningLib = cls.library;

  return cls.fields
      .where((FieldElement f) =>
          !f.isStatic && !f.isSynthetic && !f.isPrivate) // skip _foo
      .map((FieldElement f) {
    final DartType dt = f.type;
    final Uri uri = _importForType(dt, owningLib); // helper below
    return _FieldInfo(
        f.name, dt.getDisplayString(withNullability: true), uri, dt);
  }).toList(growable: false);
}

Uri _importForType(DartType type, LibraryElement targetLib) {
  Element? decl = switch (type) {
    InterfaceType(:final element) => element,
    //TypeAliasType(:final element) => element,
    FunctionType(:final element?) => element, // typedef’d function
    _ => null, // dynamic, void, etc.
  };

  if (decl == null) return Uri(); // built‑in, needs no import

  final LibraryElement lib = decl.library!;
  return identical(lib, targetLib) ? Uri() : lib.source.uri;
}

class _ChildModelInfo {
  const _ChildModelInfo(
      this.typeName, this.isUnique, this.importUri, this.element);

  final String typeName;
  final bool isUnique;
  final Uri importUri;
  final ClassElement element;
}

class ModelCrudPerFileBuilder implements Builder {
  Uri _computeImportUri(InterfaceType type, LibraryElement targetLib) {
    LibraryElement definingLib = type.element.library!;
    Uri importUri = definingLib.source.uri; // eg. package:resilient_models/…
    if (definingLib == targetLib) return Uri(); // empty = skip
    return importUri;
  }

  @override
  final Map<String, List<String>> buildExtensions =
      const <String, List<String>>{
    '.dart': <String>['.crud.dart']
  };

  @override
  Future<void> build(BuildStep step) async {
    AssetId input = step.inputId;
    if (input.path.endsWith('.g.dart') ||
        input.path.endsWith('.mapper.dart') ||
        input.path.endsWith('.crud.dart')) return;

    LibraryElement lib = await step.resolver.libraryFor(input);
    Iterable<ClassElement> classes = LibraryReader(lib).classes;

    List<String> outLines = <String>[];
    List<String> imports = <String>[];
    for (ClassElement cls in classes) {
      if (!_hasModelCrudMixin(cls)) continue;

      PropertyAccessorElement? childGetter =
          cls.lookUpGetter('childModels', cls.library);

      if (childGetter == null) continue;

      AstNode? getterNode =
          await step.resolver.astNodeFor(childGetter, resolve: true);
      if (getterNode is! MethodDeclaration) continue;

      FunctionBody body = getterNode.body;
      Expression? expr = switch (body) {
        ExpressionFunctionBody(:final expression) => expression,
        BlockFunctionBody(:final block) =>
          block.statements.whereType<ReturnStatement>().first.expression,
        _ => null
      };
      if (expr is! ListLiteral) continue;

      List<_ChildModelInfo> infos = _readFireModels(expr, cls.library);

      (String, String) o = _genCrudExtensions(cls, infos);
      imports.add(o.$1);
      outLines.add(o.$2);
    }

    if (outLines.isEmpty) return;

    AssetId output = input.changeExtension('.crud.dart');
    await step.writeAsString(
      output,
      '// GENERATED – do not modify.\nimport \'${input.uri}\';\n${imports.join("\n")}\n' +
          outLines.join('\n'),
    );
  }

  bool _hasModelCrudMixin(ClassElement cls) =>
      cls.mixins.any((InterfaceType m) => m.element?.name == 'ModelCrud');
  DartType? innerOfList(DartType t) {
    if (t is! InterfaceType) return null;
    if (!t.isDartCoreList) return null;
    return t.typeArguments.isNotEmpty ? t.typeArguments.first : null;
  }

  bool _isEnum(DartType t) {
    if (t.element is EnumElement) return true;
    Element? aliased = (t as dynamic).alias?.element;
    return aliased is EnumElement;
  }

  List<_ChildModelInfo> _readFireModels(
      ListLiteral literal, LibraryElement owningLibrary) {
    List<_ChildModelInfo> result = <_ChildModelInfo>[];

    for (CollectionElement elt in literal.elements) {
      if (elt is! InstanceCreationExpression) continue;

      TypeAnnotation? typeAnn =
          elt.constructorName.type.typeArguments?.arguments.firstOrNull;
      if (typeAnn == null) continue;

      DartType? dt = (typeAnn).type;
      if (dt is! InterfaceType) continue;

      bool unique = elt.argumentList.arguments.whereType<NamedExpression>().any(
          (NamedExpression ne) => ne.name.label.name == 'exclusiveDocumentId');

      Uri importUri = _computeImportUri(dt, owningLibrary);

      result.add(_ChildModelInfo(dt.getDisplayString(withNullability: false),
          unique, importUri, dt.element as ClassElement));
    }
    return result;
  }

  (String, String) _genCrudExtensions(
      ClassElement cls, List<_ChildModelInfo> infos) {
    StringBuffer b = StringBuffer();
    StringBuffer imports = StringBuffer();

    String c = cls.name;
    List<_FieldInfo> fields = _fieldsOf(cls);
    String mapEntries = fields
        .map((f) =>
            '${f.name} == null ? null : MapEntry("${f.name}", ${f.name})')
        .join(',\n    ');

    bool safeField(_FieldInfo info) =>
        info.type == "String" ||
        info.type == "String?" ||
        info.type == "int" ||
        info.type == "int?" ||
        info.type == "double" ||
        info.type == "double?" ||
        info.type == "bool" ||
        info.type == "bool?";

    List<String> par = [];
    List<String> imp = [];

    for (_FieldInfo i in fields
        .where((s) => !s.type.startsWith("List<") && !s.type.startsWith("Map<"))
        .where((s) => !safeField(s))) {
      imports.writeln("import '${i.importUri}';");

      par.add("${i.type.endsWith("?") ? i.type : "${i.type}?"} ${i.name}");

      if (i.type == "DateTime" || i.type == "DateTime?") {
        imp.add(
            "if(${i.name} != null) '${i.name}': ${i.name}.toIso8601String()");
      } else {
        imp.add(
            "if(${i.name} != null) '${i.name}': ${i.name}${_isEnum(i.dartType) ? ".name" : ".toMap()"}");
      }
    }

    for (_FieldInfo i in fields.where((s) => s.type.startsWith("List<"))) {
      DartType? itype = innerOfList(i.dartType);

      if (itype == null) {
        continue;
      }

      Uri iuri = _importForType(itype, cls.library); // helper below
      imports.writeln("import '$iuri';");
      String mapV() {
        if (itype.name == "DateTime" || itype.name == "DateTime?") {
          return "v.toIso8601String()";
        }

        if (_isEnum(itype)) {
          return "v.name";
        }

        if (itype.name == "int?" ||
            itype.name == "int" ||
            itype.name == "double?" ||
            itype.name == "double" ||
            itype.name == "String?" ||
            itype.name == "String" ||
            itype.name == "bool?" ||
            itype.name == "bool") {
          return "v";
        }

        return "v.toMap()";
      }

      par.add(
          "${i.type.endsWith("?") ? i.type : "${i.type}?"} add${i.name.capitalize()}");
      par.add(
          "${i.type.endsWith("?") ? i.type : "${i.type}?"} remove${i.name.capitalize()}");
      imp.add(
          "if(add${i.name.capitalize()} != null && add${i.name.capitalize()}.isNotEmpty) '${i.name}': FieldValue.arrayUnion(add${i.name.capitalize()}.map((v) => ${mapV()}).toList())");
      imp.add(
          "if(remove${i.name.capitalize()} != null && remove${i.name.capitalize()}.isNotEmpty) '${i.name}': FieldValue.arrayRemove(remove${i.name.capitalize()}.map((v) => ${mapV()}).toList())");
    }

    b.writeln('''
/// CRUD Extensions for ${cls.name}
extension XFCrudBase\$${cls.name} on ${cls.name} {
  /// Gets this document (self) live and returns a new instance of [$c] representing the new data
  Future<$c?> get() => getSelfRaw<$c>();
  
  /// Opens a self stream of [$c] representing this document
  Stream<$c?> stream() => streamSelfRaw<$c>();
  
  /// Sets this [$c] document to a new value
  Future<void> set($c to) => setSelfRaw<$c>(to);
  
  /// Updates properties of this [$c] with {"fieldName": VALUE, ...}
  Future<void> update(Map<String, dynamic> u) => updateSelfRaw<$c>(u);
  
  /// Deletes this [$c] document
  Future<void> delete() => deleteSelfRaw<$c>();
  
  /// Sets this [$c] document atomically by getting first then setting.
  Future<void> setAtomic($c Function($c?) txn) => setSelfAtomicRaw<$c>(txn);
  
  Future<void> mutate({${fields.where(safeField).map((f) => '${f.type.endsWith("?") ? f.type : "${f.type}?"} ${f.name}').followedBy(par).followedBy(fields.where(safeField).where((f) => f.type == "int?" || f.type == "int").map((f) => "int? increment${f.name.capitalize()}")).followedBy(fields.where(safeField).where((f) => f.type == "double?" || f.type == "double").map((f) => "double? increment${f.name.capitalize()}")).followedBy(fields.where(safeField).where((f) => f.type == "int?" || f.type == "int").map((f) => "int? decrement${f.name.capitalize()}")).followedBy(fields.where(safeField).where((f) => f.type == "double?" || f.type == "double").map((f) => "double? decrement${f.name.capitalize()}")).followedBy(fields.map((f) => 'bool delete${f.name.capitalize()} = false')).join(', ')}}) =>
    updateSelfRaw<$c>({ 
      ${fields.where(safeField).map((f) => "if(${f.name} != null) '${f.name}': ${f.name}").followedBy(imp).followedBy(fields.where(safeField).where((f) => f.type == "int?" || f.type == "int").map((f) => "if(increment${f.name.capitalize()} != null) '${f.name}': FieldValue.increment(increment${f.name.capitalize()})")).followedBy(fields.where(safeField).where((f) => f.type == "double?" || f.type == "double").map((f) => "if(increment${f.name.capitalize()} != null) '${f.name}': FieldValue.increment(increment${f.name.capitalize()})")).followedBy(fields.where(safeField).where((f) => f.type == "int?" || f.type == "int").map((f) => "if(decrement${f.name.capitalize()} != null) '${f.name}': FieldValue.decrement(decrement${f.name.capitalize()})")).followedBy(fields.where(safeField).where((f) => f.type == "double?" || f.type == "double").map((f) => "if(decrement${f.name.capitalize()} != null) '${f.name}': FieldValue.decrement(decrement${f.name.capitalize()})")).followedBy(fields.map((f) => "if(delete${f.name.capitalize()}) '${f.name}': FieldValue.delete()")).join(",\n")}
    });
}
    ''');

    imports.writeln("import 'package:fire_api/fire_api.dart';");

    for (_ChildModelInfo info in infos) {
      String t = info.typeName;
      imports.writeln("import '${info.importUri}';");

      if (info.isUnique) {
        b.writeln('''
/// CRUD Extensions for (UNIQUE) ${cls.name}.${t}
extension XFCrudU\$${cls.name}\$${t} on ${cls.name} {
  Future<$t> get$t() => get<$t>();
  Future<void> set$t($t value) => setUnique<$t>(value);
  Future<void> delete$t() => deleteUnique<$t>();
  Stream<$t> stream$t() => streamUnique<$t>();
  Future<void> update$t(Map<String, dynamic> updates) => updateUnique<$t>(updates);
  Future<void> set${t}Atomic($t Function($t?) txn) => setUniqueAtomic<$t>(txn);
  Future<void> ensure${t}Exists($t or) => ensureExistsUnique<$t>(or);
  $t ${_camel(t)}Model() => modelUnique<$t>();
} 
''');
      } else {
        String plural = '${t}s';
        b.writeln('''
/// CRUD Extensions for ${cls.name}.${t}
extension XFCrud\$${cls.name}\$${t} on ${cls.name} {
  Future<List<$t>> get$plural([CollectionReference Function(CollectionReference ref)? query]) => getAll<$t>(query);
  Stream<List<$t>> stream$plural([CollectionReference Function(CollectionReference ref)? query]) => streamAll<$t>(query);
  Future<void> set$t(String id, $t value) => set<$t>(id, value);
  Future<void> update$t(String id, Map<String, dynamic> updates) => update<$t>(id, updates);
  Stream<$t?> stream$t(String id) => stream<$t>(id);
  Future<void> delete$t(String id) => delete<$t>(id);
  Future<void> add${t}($t value) => add<$t>(value);
  Future<void> set${t}Atomic(String id, $t Function($t?) txn) => setAtomic<$t>(id, txn);
  Future<void> ensure${t}Exists(String id, $t or) => ensureExists<$t>(id, or);
  $t ${_camel(t)}Model(String id) => model<$t>();
}
''');
      }
    }
    return (imports.toString(), b.toString());
  }

  String _camel(String s) => s[0].toLowerCase() + s.substring(1);
  String _Camel(String s) => s;
}
