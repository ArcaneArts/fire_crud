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

class _ChildModelInfo {
  const _ChildModelInfo(
      this.typeName, this.isUnique, this.importUri, this.element);

  final String typeName;
  final bool isUnique;
  final Uri importUri;
  final ClassElement element;
}

List<_FieldInfo> fieldsOf(ClassElement cls) {
  final LibraryElement owningLib = cls.library;

  return cls.fields
      .where((FieldElement f) =>
          !f.isStatic && !f.isSynthetic && !f.isPrivate) // skip _foo
      .map((FieldElement f) {
    final DartType dt = f.type;
    final Uri uri = importForType(dt, owningLib); // helper below
    return _FieldInfo(
        f.name, dt.getDisplayString(withNullability: true), uri, dt);
  }).toList(growable: false);
}

Uri importForType(DartType type, LibraryElement targetLib) {
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

  bool isSafeField(_FieldInfo info) =>
      info.type == "String" ||
      info.type == "String?" ||
      info.type == "int" ||
      info.type == "int?" ||
      info.type == "double" ||
      info.type == "double?" ||
      info.type == "bool" ||
      info.type == "bool?";

  (String, String) _genCrudExtensions(
      ClassElement cls, List<_ChildModelInfo> infos) {
    StringBuffer b = StringBuffer();
    StringBuffer importsX = StringBuffer();
    List<String> imports = [];

    String c = cls.name;
    List<_FieldInfo> fields = fieldsOf(cls);
    (List<String>, List<String>, List<String>) mutate =
        mutateParams(fields, cls);
    imports.addAll(mutate.$1);

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
  
  Future<void> mutate({\n    ${mutate.$2.join(',\n    ')}\n  }) =>
    updateSelfRaw<$c>({ 
      ${mutate.$3.join(",\n      ")}
    });
}
    ''');

    imports.add("import 'package:fire_api/fire_api.dart';");

    for (_ChildModelInfo info in infos) {
      String t = info.typeName;
      imports.add("import '${info.importUri}';");

      if (info.isUnique) {
        List<_FieldInfo> fieldsU = fieldsOf(info.element);
        (List<String>, List<String>, List<String>) mutateU =
            mutateParams(fieldsU, info.element);
        imports.addAll(mutateU.$1);

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
  $t ${lowCamel(t)}Model() => modelUnique<$t>();
  Future<void> mutate$t({\n    ${mutateU.$2.join(',\n    ')}\n  }) =>
    updateUnique<$t>({ 
      ${mutateU.$3.join(",\n      ")}
    });
} 
''');
      } else {
        String plural = '${t}s';
        List<_FieldInfo> fieldsC = fieldsOf(info.element);
        (List<String>, List<String>, List<String>) mutateC =
            mutateParams(fieldsC, info.element);
        imports.addAll(mutateC.$1);
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
  $t ${lowCamel(t)}Model(String id) => model<$t>();
  Future<void> mutate$t({\n    required String id,\n    ${mutateC.$2.join(',\n    ')}\n  }) =>
    update<$t>(id, { 
      ${mutateC.$3.join(",\n      ")}
    });
}
''');
      }
    }
    importsX.writeln(imports.join("\n"));
    return (importsX.toString(), b.toString());
  }

  String mapVX(DartType dt) {
    String type = dt.name!;
    if (type == "DateTime" || type == "DateTime?") {
      return ".toIso8601String()";
    }

    if (_isEnum(dt)) {
      return ".name";
    }

    if (type == "int?" ||
        type == "int" ||
        type == "double?" ||
        type == "double" ||
        type == "String?" ||
        type == "String" ||
        type == "bool?" ||
        type == "bool") {
      return "";
    }

    return ".toMap()";
  }

  // import param impl
  (List<String>, List<String>, List<String>) mutateParams(
      List<_FieldInfo> fields, ClassElement cls) {
    List<String> imports = [];
    List<String> params = [];
    List<String> impl = [];
    String cmt(String src, {String? comment}) {
      if (comment == null) {
        return src;
      }

      return "\n    /// $comment\n    $src";
    }

    for (_FieldInfo f in fields) {
      bool accept = false;

      if (isSafeField(f)) {
        accept = true;
        impl.add("if(${f.name} != null) '${f.name}': ${f.name}");

        if (f.type == "int?" || f.type == "int") {
          params.add(cmt("int? increment${f.name.capitalize()}",
              comment:
                  "Increases [${f.name}] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value."));
          impl.add(
              "if(increment${f.name.capitalize()} != null) '${f.name}': FieldValue.increment(increment${f.name.capitalize()})");

          params.add(cmt("int? decrement${f.name.capitalize()}",
              comment:
                  "Reduces [${f.name}] by an amount atomically using FieldValue.decrement() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value."));
          impl.add(
              "if(decrement${f.name.capitalize()} != null) '${f.name}': FieldValue.decrement(decrement${f.name.capitalize()})");
        }

        if (f.type == "double?" || f.type == "double") {
          params.add(cmt("double? increment${f.name.capitalize()}",
              comment:
                  "Increases [${f.name}] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value."));
          impl.add(
              "if(increment${f.name.capitalize()} != null) '${f.name}': FieldValue.increment(increment${f.name.capitalize()})");
          params.add(cmt("double? decrement${f.name.capitalize()}",
              comment:
                  "Reduces [${f.name}] by an amount atomically using FieldValue.decrement() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value."));
          impl.add(
              "if(decrement${f.name.capitalize()} != null) '${f.name}': FieldValue.decrement(decrement${f.name.capitalize()})");
        }
      } else {
        if (f.type == "DateTime" || f.type == "DateTime?") {
          accept = true;
          impl.add(
              "if(${f.name} != null) '${f.name}': ${f.name}.toIso8601String()");
        } else if (_isEnum(f.dartType)) {
          accept = true;
          impl.add("if(${f.name} != null) '${f.name}': ${f.name}.name");
        } else if (f.type.startsWith("List<")) {
          DartType? itype = innerOfList(f.dartType);
          if (itype == null) {
            continue;
          }

          Uri iuri = importForType(itype, cls.library); // helper below
          imports.add("import '$iuri';");

          params.add(cmt(
              "${f.type.endsWith("?") ? f.type : "${f.type}?"} add${f.name.capitalize()}",
              comment:
                  "Adds multiple [${itype.name}] to the [${f.name}] field atomically using FieldValue.arrayUnion(). See https://cloud.google.com/firestore/docs/manage-data/add-data#update_elements_in_an_array"));
          params.add(cmt(
              "${f.type.endsWith("?") ? f.type : "${f.type}?"} remove${f.name.capitalize()}",
              comment:
                  "Removes one or more [${itype.name}] to the [${f.name}] field atomically using FieldValue.arrayRemove(). See https://cloud.google.com/firestore/docs/manage-data/add-data#update_elements_in_an_array"));
          impl.add(
              "if(add${f.name.capitalize()} != null && add${f.name.capitalize()}.isNotEmpty) '${f.name}': FieldValue.arrayUnion(add${f.name.capitalize()}.map((v) => v${mapVX(itype)}).toList())");
          impl.add(
              "if(remove${f.name.capitalize()} != null && remove${f.name.capitalize()}.isNotEmpty) '${f.name}': FieldValue.arrayRemove(remove${f.name.capitalize()}.map((v) => v${mapVX(itype)}).toList())");

          accept = true;
        } else if (!f.type.startsWith("Map<")) {
          accept = true;
          impl.add("if(${f.name} != null) '${f.name}': ${f.name}.toMap()");
        }
      }

      if (accept) {
        params.add(cmt(
            '${f.type.endsWith("?") ? f.type : "${f.type}?"} ${f.name}',
            comment:
                "Replaces the value of [${f.name}] with a new value atomically."));
        imports.add('import "${importForType(f.dartType, cls.library)}";');
      }

      params.add(cmt('bool delete${f.name.capitalize()} = false',
          comment:
              "Removes the [${f.name}] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields"));
      impl.add(
          "if(delete${f.name.capitalize()}) '${f.name}': FieldValue.delete()");
    }

    return (imports.toSet().toList(), params, impl);
  }

  String lowCamel(String s) => s[0].toLowerCase() + s.substring(1);
}
