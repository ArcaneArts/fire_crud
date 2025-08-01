import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:artifact/artifact.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
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
    this.typeName,
    this.isUnique,
    this.importUri,
    this.element,
  );

  final String typeName;
  final bool isUnique;
  final Uri importUri;
  final ClassElement element;
}

List<_FieldInfo> fieldsOf(ClassElement cls) {
  final Map<String, _FieldInfo> seen = <String, _FieldInfo>{};
  ClassElement? current = cls;

  while (current != null && !current.isDartCoreObject) {
    final LibraryElement owningLib = current.library;

    // `fields` gives only the declarations on `current`, not inherited ones.
    for (final FieldElement f in current.fields) {
      if (f.isStatic || f.isSynthetic || f.isPrivate) continue;
      if (seen.containsKey(f.name)) continue; // overridden

      final DartType dt = f.type;
      final Uri uri = importForType(dt, owningLib);

      seen[f.name] = _FieldInfo(
        f.name,
        dt.getDisplayString(withNullability: true),
        uri,
        dt,
      );
    }

    final InterfaceType? superType = current.supertype;
    current = superType?.element as ClassElement?;
  }

  return seen.values.toList(growable: false);
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
  Map<String, List<String>> get buildExtensions => const <String, List<String>>{
    r'$lib$': <String>['gen/crud.gen.dart'],
  };
  static Glob $dartFilesInLib = Glob('lib/**.dart');
  static final TypeChecker $artifactChecker = TypeChecker.fromRuntime(Artifact);

  @override
  Future<void> build(BuildStep step) async {
    assert(step.inputId.path == r'$lib$');

    List<String> outLines = <String>[];
    List<String> imports = <String>[];
    await for (AssetId asset in step.findAssets($dartFilesInLib)) {
      if (!await step.resolver.isLibrary(asset)) continue;
      LibraryElement lib = await step.resolver.libraryFor(asset);
      Iterable<ClassElement> classes = LibraryReader(lib).classes;

      for (ClassElement cls in classes) {
        if (!_hasModelCrudMixin(cls)) continue;

        PropertyAccessorElement? childGetter = cls.lookUpGetter(
          'childModels',
          cls.library,
        );

        if (childGetter == null) continue;

        AstNode? getterNode = await step.resolver.astNodeFor(
          childGetter,
          resolve: true,
        );
        if (getterNode is! MethodDeclaration) continue;

        FunctionBody body = getterNode.body;
        Expression? expr = switch (body) {
          ExpressionFunctionBody(:final expression) => expression,
          BlockFunctionBody(:final block) =>
            block.statements.whereType<ReturnStatement>().first.expression,
          _ => null,
        };
        if (expr is! ListLiteral) continue;

        List<_ChildModelInfo> infos = _readFireModels(expr, cls.library);
        imports.add("import '${cls.source.uri}';");

        if ($artifactChecker.hasAnnotationOf(cls, throwOnUnresolved: false)) {
          imports.add(
            "import '${cls.source.uri.replace(path: "${cls.source.uri.pathSegments[0]}/gen/artifacts.gen.dart")}';",
          );
        }

        (String, String) o = _genCrudExtensions(cls, infos);
        imports.add(o.$1);
        outLines.add(o.$2);
      }
    }

    AssetId out = AssetId(step.inputId.package, 'lib/gen/crud.gen.dart');
    await step.writeAsString(
      out,
      '// GENERATED – do not modify.\n${imports.join("\n")}\n' +
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
    ListLiteral literal,
    LibraryElement owningLibrary,
  ) {
    List<_ChildModelInfo> result = <_ChildModelInfo>[];

    for (CollectionElement elt in literal.elements) {
      if (elt is! InstanceCreationExpression) continue;

      TypeAnnotation? typeAnn =
          elt.constructorName.type.typeArguments?.arguments.firstOrNull;
      if (typeAnn == null) continue;

      DartType? dt = (typeAnn).type;
      if (dt is! InterfaceType) continue;

      bool unique = elt.argumentList.arguments.whereType<NamedExpression>().any(
        (NamedExpression ne) => ne.name.label.name == 'exclusiveDocumentId',
      );

      Uri importUri = _computeImportUri(dt, owningLibrary);

      result.add(
        _ChildModelInfo(
          dt.getDisplayString(withNullability: false),
          unique,
          importUri,
          dt.element as ClassElement,
        ),
      );
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
    ClassElement cls,
    List<_ChildModelInfo> infos,
  ) {
    StringBuffer b = StringBuffer();
    StringBuffer importsX = StringBuffer();
    List<String> imports = [];

    String c = cls.name;
    List<_FieldInfo> fields = fieldsOf(cls);
    (List<String>, List<String>, List<String>) mutate = mutateParams(
      fields,
      cls,
    );
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
  
  Future<void> modify({\n    ${mutate.$2.followedBy(["bool \$z = false"]).join(',\n    ')}\n  }) =>
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
        (List<String>, List<String>, List<String>) mutateU = mutateParams(
          fieldsU,
          info.element,
        );
        imports.addAll(mutateU.$1);

        b.writeln('''
/// CRUD Extensions for (UNIQUE) ${cls.name}.${t}
extension XFCrudU\$${cls.name}\$${t} on ${cls.name} {
  Future<$t?> get$t() => getUnique<$t>();
  Future<void> set$t($t value) => setUnique<$t>(value);
  Future<void> delete$t() => deleteUnique<$t>();
  Stream<$t?> stream$t() => streamUnique<$t>(); 
  Future<void> update$t(Map<String, dynamic> updates) => updateUnique<$t>(updates);
  Future<void> set${t}Atomic($t Function($t?) txn) => setUniqueAtomic<$t>(txn);
  Future<void> ensure${t}Exists($t or) => ensureExistsUnique<$t>(or);
  $t ${lowCamel(t)}Model() => modelUnique<$t>();
  Future<void> modify$t({\n    ${mutateU.$2.followedBy(["bool \$z = false"]).join(',\n    ')}\n  }) =>
    updateUnique<$t>({ 
      ${mutateU.$3.join(",\n      ")}
    });
} 
''');
      } else {
        String plural = '${t}s';
        List<_FieldInfo> fieldsC = fieldsOf(info.element);
        (List<String>, List<String>, List<String>) mutateC = mutateParams(
          fieldsC,
          info.element,
        );
        imports.addAll(mutateC.$1);
        b.writeln('''
/// CRUD Extensions for ${cls.name}.${t}
extension XFCrud\$${cls.name}\$${t} on ${cls.name} {
  Future<List<$t>> get$plural([CollectionReference Function(CollectionReference ref)? query]) => getAll<$t>(query);
  Stream<List<$t>> stream$plural([CollectionReference Function(CollectionReference ref)? query]) => streamAll<$t>(query);
  Future<void> set$t(String id, $t value) => \$set<$t>(id, value);
  Future<$t?> get$t(String id) => \$get<$t>(id);
  Future<void> update$t(String id, Map<String, dynamic> updates) => \$update<$t>(id, updates);
  Stream<$t?> stream$t(String id) => \$stream<$t>(id);
  Future<void> delete$t(String id) => \$delete<$t>(id);
  Future<$t> add${t}($t value) => \$add<$t>(value);
  Future<void> set${t}Atomic(String id, $t Function($t?) txn) => \$setAtomic<$t>(id, txn);
  Future<void> ensure${t}Exists(String id, $t or) => \$ensureExists<$t>(id, or);
  $t ${lowCamel(t)}Model(String id) => \$model<$t>(id);
  Future<void> modify$t({\n    required String id,\n    ${mutateC.$2.followedBy(["bool \$z = false"]).join(',\n    ')}\n  }) =>
    \$update<$t>(id, { 
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
        type == "bool" ||
        type == "Map" ||
        type == "Map?") {
      return "";
    }

    return ".toMap()";
  }

  // import param impl
  (List<String>, List<String>, List<String>) mutateParams(
    List<_FieldInfo> fields,
    ClassElement cls,
  ) {
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
          params.add(
            cmt(
              "int? delta${f.name.capitalize()}",
              comment:
                  "Changes (increment/decrement) [${f.name}] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.",
            ),
          );
          impl.add(
            "if(delta${f.name.capitalize()} != null) '${f.name}': FieldValue.increment(delta${f.name.capitalize()})",
          );
        }

        if (f.type == "double?" || f.type == "double") {
          params.add(
            cmt(
              "double? delta${f.name.capitalize()}",
              comment:
                  "Changes (increment/decrement) [${f.name}] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.",
            ),
          );
          impl.add(
            "if(delta${f.name.capitalize()} != null) '${f.name}': FieldValue.increment(delta${f.name.capitalize()})",
          );
        }
      } else {
        if (f.type == "DateTime" || f.type == "DateTime?") {
          accept = true;
          impl.add(
            "if(${f.name} != null) '${f.name}': ${f.name}.toIso8601String()",
          );
        } else if (_isEnum(f.dartType)) {
          accept = true;
          impl.add("if(${f.name} != null) '${f.name}': ${f.name}.name");
        } else if (f.type.startsWith("List<") || f.type.startsWith("Set<")) {
          DartType? itype = innerOfList(f.dartType);
          if (itype == null) {
            continue;
          }

          Uri iuri = importForType(itype, cls.library); // helper below
          imports.add("import '$iuri';");

          params.add(
            cmt(
              "${f.type.endsWith("?") ? f.type : "${f.type}?"} add${f.name.capitalize()}",
              comment:
                  "Adds multiple [${itype.name}] to the [${f.name}] field atomically using FieldValue.arrayUnion(). See https://cloud.google.com/firestore/docs/manage-data/add-data#update_elements_in_an_array",
            ),
          );
          params.add(
            cmt(
              "${f.type.endsWith("?") ? f.type : "${f.type}?"} remove${f.name.capitalize()}",
              comment:
                  "Removes one or more [${itype.name}] to the [${f.name}] field atomically using FieldValue.arrayRemove(). See https://cloud.google.com/firestore/docs/manage-data/add-data#update_elements_in_an_array",
            ),
          );
          impl.add(
            "if(add${f.name.capitalize()} != null && add${f.name.capitalize()}.isNotEmpty) '${f.name}': FieldValue.arrayUnion(add${f.name.capitalize()}.map((v) => v${mapVX(itype)}).toList())",
          );
          impl.add(
            "if(remove${f.name.capitalize()} != null && remove${f.name.capitalize()}.isNotEmpty) '${f.name}': FieldValue.arrayRemove(remove${f.name.capitalize()}.map((v) => v${mapVX(itype)}).toList())",
          );

          accept = true;
        } else if (!f.type.startsWith("Map<")) {
          accept = true;
          impl.add("if(${f.name} != null) '${f.name}': ${f.name}.toMap()");
        }
      }

      if (accept) {
        params.add(
          cmt(
            '${f.type.endsWith("?") ? f.type : "${f.type}?"} ${f.name}',
            comment:
                "Replaces the value of [${f.name}] with a new value atomically.",
          ),
        );
        imports.add('import "${importForType(f.dartType, cls.library)}";');
      }

      params.add(
        cmt(
          'bool delete${f.name.capitalize()} = false',
          comment:
              "Removes the [${f.name}] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields",
        ),
      );
      impl.add(
        "if(delete${f.name.capitalize()}) '${f.name}': FieldValue.delete()",
      );
    }

    return (imports.toSet().toList(), params, impl);
  }

  String lowCamel(String s) => s[0].toLowerCase() + s.substring(1);
}
