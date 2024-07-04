import 'package:fire_crud/fire_crud.dart';

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

  T cloneWithPath(String path) => fromMap(toMap(model))..documentPath = path;

  T? withPath(Map<String, dynamic>? data, String path) =>
      data == null ? null : (fromMap(data)..documentPath = path);

  FireModel(
      {required this.collection,
      required this.model,
      required this.toMap,
      required this.fromMap,
      this.exclusiveDocumentId});

  void registerTypeModels() {
    for (FireModel i in model.childModels) {
      FireCrud.instance().typeModels[i.model.runtimeType] = i;
      i.registerTypeModels();
    }
  }
}
