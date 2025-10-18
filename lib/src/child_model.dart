import 'package:fire_crud/fire_crud.dart';
import 'package:pylon_codec/pylon_codec.dart';

Map<Type, int> _rc = {};

Map<String, dynamic> Function(Object o)? _fcaToMap;
T Function<T>(Map<String, dynamic> m)? _fcaFromMap;
T Function<T>()? _fcaConstruct;

void registerFCA(
  T Function<T>(Map<String, dynamic> m) artifactFromMap,
  Map<String, dynamic> Function(Object o) artifactToMap,
  T Function<T>() artifactConstruct,
) {
  _fcaToMap = artifactToMap;
  _fcaFromMap = artifactFromMap;
  _fcaConstruct = artifactConstruct;
}

void _checkFCA() {
  if (_fcaFromMap == null || _fcaToMap == null) {
    throw Exception(
        "FireCrud is trying to use artifact, please call `registerFCA(\$artifactFromMap, \$artifactToMap, \$constructArtifact);` during initialization.");
  }
}

/// Represents a model that can be used in its parent. These tell fire_crud the type, and how to convert to and from a map.
/// Make sure to actually specify the T type otherwise it may not work correctly.
class FireModel<T extends ModelCrud> {
  /// The subCollection that this child is a part of
  final String collection;

  /// The document id that this child is a part of if it is exclusive otherwise keep this null.
  final String? exclusiveDocumentId;

  /// The model that this child is a part of
  final T model;

  final Map<String, dynamic> Function(T crud) toMap;
  final T Function(Map<String, dynamic>) fromMap;
  late String templatePath;
  String get parentTemplatePath => _parentPath(templatePath);

  T cloneWithPath(String path, [T? useModel]) =>
      fromMap(toMap(useModel ?? model))..documentPath = path;

  T? withPath(Map<String, dynamic>? data, String path) =>
      data == null ? null : (fromMap(data)..documentPath = path);

  FireModel(
      {required this.collection,
      required this.model,
      required this.toMap,
      required this.fromMap,
      this.exclusiveDocumentId});

  factory FireModel.artifact(String collectionName,
      {String? exclusiveDocumentId}) {
    _checkFCA();
    return FireModel<T>(
        collection: collectionName,
        exclusiveDocumentId: exclusiveDocumentId,
        model: _fcaConstruct!<T>(),
        toMap: _fcaToMap!,
        fromMap: _fcaFromMap!);
  }

  void registerTypeModels() {
    if ((_rc[model.runtimeType] ?? 0) > 10) {
      return;
    }

    _rc[model.runtimeType] = (_rc[model.runtimeType] ?? 0) + 1;

    registerPylonCodec(model);

    for (FireModel i in model.childModels) {
      FireCrud.instance().typeModels[i.model.runtimeType] = i;
      i.templatePath =
          "$templatePath/${"${i.collection}/\$${i.model.runtimeType}.id"}";
      i.registerTypeModels();
    }
  }
}

String _parentPath(String path) {
  List<String> s = path.split("/");
  s.removeLast();
  s.removeLast();
  return s.join("/");
}
