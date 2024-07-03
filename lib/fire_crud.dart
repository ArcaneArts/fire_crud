library fire_crud;

import 'package:collection_walker/collection_walker.dart';
import 'package:fire_api/fire_api.dart';
import 'package:toxic/extensions/iterable.dart';

class ChildModel<T extends ModelCrud> {
  /// The subCollection that this child is a part of
  final String collection;

  /// The document id that this child is a part of if it is exclusive otherwise keep this null
  final String? exclusiveDocumentId;

  /// The model that this child is a part of
  final T model;

  final Map<String, dynamic> Function(T crud) toMap;
  final T Function(Map<String, dynamic>) fromMap;

  T cloneWithPath(String path) => fromMap(toMap(model))..documentPath = path;

  T? withPath(Map<String, dynamic>? data, String path) =>
      data == null ? null : (fromMap(data)..documentPath = path);

  ChildModel(
      {required this.collection,
      required this.model,
      required this.toMap,
      required this.fromMap,
      this.exclusiveDocumentId});
}

ChildModel<T>? selectChildModel<T extends ModelCrud>(List<ChildModel> models,
    [String? id]) {
  return models
      .whereType<ChildModel<T>>()
      .select((e) => (e.exclusiveDocumentId != null) != (id != null));
}

ChildModel<T>? selectChildModelByCollection<T extends ModelCrud>(
    List<ChildModel> models, String collection,
    [String? id]) {
  return models.where((e) => e.collection == collection) as ChildModel<T>;
}

ChildModel<T>? selectChildModelCollectionByType<T extends ModelCrud>(
    List<ChildModel> models) {
  return models
      .whereType<ChildModel<T>>()
      .select((e) => e.exclusiveDocumentId == null);
}

class ModelUtility {
  static CollectionWalker<T> _walk<T extends ModelCrud>(
      String collectionPath, List<ChildModel> models,
      [CollectionReference Function(CollectionReference ref)? query]) {
    ChildModel<T> c = selectChildModelCollectionByType(models)!;
    return CollectionWalker<T>(
      query:
          (query?.call(FirestoreDatabase.instance.collection(collectionPath)) ??
              FirestoreDatabase.instance.collection(collectionPath)),
      documentConverter: (doc) async => c.withPath(doc.data ?? {}, doc.path)!,
    );
  }

  static Future<List<T>> _pullAll<T extends ModelCrud>(
      String collectionPath, List<ChildModel> models,
      [CollectionReference Function(CollectionReference ref)? query]) {
    ChildModel<T> c = selectChildModelCollectionByType(models)!;
    return (query
                ?.call(FirestoreDatabase.instance.collection(collectionPath)) ??
            FirestoreDatabase.instance.collection(collectionPath))
        .get()
        .then((value) =>
            value.map((e) => c.withPath(e.data, e.reference.path)!).toList());
  }

  static Stream<List<T>> _streamAll<T extends ModelCrud>(
      String collectionPath, List<ChildModel> models,
      [CollectionReference Function(CollectionReference ref)? query]) {
    ChildModel<T> c = selectChildModelCollectionByType<T>(models)!;
    return (query
                ?.call(FirestoreDatabase.instance.collection(collectionPath)) ??
            FirestoreDatabase.instance.collection(collectionPath))
        .stream
        .map((event) =>
            event.map((e) => c.withPath(e.data, e.reference.path)!).toList());
  }

  static Future<int> _count<T extends ModelCrud>(
      String collectionPath, List<ChildModel> models,
      [CollectionReference Function(CollectionReference ref)? query]) {
    return (query
                ?.call(FirestoreDatabase.instance.collection(collectionPath)) ??
            FirestoreDatabase.instance.collection(collectionPath))
        .count();
  }

  static T _model<T extends ModelCrud>(List<ChildModel> models,
      String Function(ChildModel c, [String? id]) pathOf,
      [String? id]) {
    ChildModel<T> c = selectChildModel<T>(models, id)!;
    return c.cloneWithPath(pathOf(c, id));
  }

  static T _modelInCollection<T extends ModelCrud>(List<ChildModel> models,
      String Function(ChildModel c, [String? id]) pathOf, String collection,
      [String? id]) {
    ChildModel<T> c = selectChildModelByCollection<T>(models, collection, id)!;
    return c.cloneWithPath(pathOf(c, id));
  }

  static Future<T?> _pull<T extends ModelCrud>(List<ChildModel> models,
      String Function(ChildModel c, [String? id]) pathOf,
      [String? id]) async {
    ChildModel<T> c = selectChildModel<T>(models, id)!;
    DocumentReference ref = FirestoreDatabase.instance.document(pathOf(c, id));
    return c.withPath((await ref.get()).data, ref.path);
  }

  static Future<void> _push<T extends ModelCrud>(List<ChildModel> models,
      String Function(ChildModel c, [String? id]) pathOf, T model,
      [String? id]) async {
    ChildModel<T> c = selectChildModel<T>(models)!;
    await FirestoreDatabase.instance
        .document(pathOf(c, id))
        .set(c.toMap(model));
  }

  static Future<void> _delete<T extends ModelCrud>(List<ChildModel> models,
      String Function(ChildModel c, [String? id]) pathOf, T model,
      [String? id]) async {
    ChildModel<T> c = selectChildModel<T>(models)!;
    await FirestoreDatabase.instance.document(pathOf(c, id)).delete();
  }

  static Future<void> _pushAtomic<T extends ModelCrud>(
      List<ChildModel> models,
      String Function(ChildModel c, [String? id]) pathOf,
      T Function(T? data) txn,
      [String? id]) async {
    ChildModel<T> c = selectChildModel<T>(models)!;
    await FirestoreDatabase.instance.document(pathOf(c, id)).setAtomic(
        (data) => c.toMap(txn(data == null ? null : c.fromMap(data))));
  }

  static Stream<T> _stream<T extends ModelCrud>(List<ChildModel> models,
      String Function(ChildModel c, [String? id]) pathOf,
      [String? id]) {
    ChildModel<T> c = selectChildModel<T>(models, id)!;
    return FirestoreDatabase.instance
        .document(pathOf(c, id))
        .stream
        .map((event) => c.withPath(event.data, event.reference.path)!);
  }

  static Future<T> _add<T extends ModelCrud>(List<ChildModel> models,
      String Function(ChildModel c, [String? id]) pathOf, T model) async {
    ChildModel<T> c = selectChildModel<T>(models)!;
    DocumentReference r = await FirestoreDatabase.instance
        .collection(c.collection)
        .add(c.toMap(model));
    return c.cloneWithPath(pathOf(c, r.path));
  }
}

abstract class ModelAccessor {
  List<ChildModel> get _models;

  String _pathOf(ChildModel c, [String? id]);

  CollectionWalker<T> walk<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  T model<T extends ModelCrud>([String? id]);

  T modelInCollection<T extends ModelCrud>(String collection, [String? id]);

  Future<T?> pull<T extends ModelCrud>([String? id]);

  Future<void> push<T extends ModelCrud>(T model, [String? id]);

  Future<void> delete<T extends ModelCrud>(T model, [String? id]);

  Future<void> pushAtomic<T extends ModelCrud>(T Function(T? data) txn,
      [String? id]);

  Stream<T> stream<T extends ModelCrud>([String? id]);

  Future<T> add<T extends ModelCrud>(T model);

  Future<List<T>> pullAll<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  Stream<List<T>> streamAll<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  Future<int> count<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);
}

class FireCrud extends ModelAccessor {
  static FireCrud? _instance;

  FireCrud._();

  factory FireCrud.instance() => _instance ??= FireCrud._();

  List<ChildModel> models = [];

  void registerModel(ChildModel root) {
    models.add(root);
  }

  @override
  CollectionWalker<T> walk<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility._walk<T>(
          selectChildModelCollectionByType(_models)!.collection,
          _models,
          query);

  @override
  String _pathOf(ChildModel c, [String? id]) =>
      "${c.collection}/${id ?? c.exclusiveDocumentId}";

  @override
  List<ChildModel<ModelCrud>> get _models => models;

  @override
  T model<T extends ModelCrud>([String? id]) =>
      ModelUtility._model<T>(_models, _pathOf, id);

  @override
  T modelInCollection<T extends ModelCrud>(String collection, [String? id]) =>
      ModelUtility._modelInCollection<T>(_models, _pathOf, collection, id);

  @override
  Future<T?> pull<T extends ModelCrud>([String? id]) =>
      ModelUtility._pull<T>(_models, _pathOf, id);

  @override
  Future<void> push<T extends ModelCrud>(T model, [String? id]) =>
      ModelUtility._push<T>(_models, _pathOf, model, id);

  @override
  Future<void> delete<T extends ModelCrud>(T model, [String? id]) =>
      ModelUtility._delete<T>(_models, _pathOf, model, id);

  @override
  Future<void> pushAtomic<T extends ModelCrud>(T Function(T? data) txn,
          [String? id]) =>
      ModelUtility._pushAtomic<T>(_models, _pathOf, txn, id);

  @override
  Stream<T> stream<T extends ModelCrud>([String? id]) =>
      ModelUtility._stream<T>(_models, _pathOf, id);

  @override
  Future<T> add<T extends ModelCrud>(T model) =>
      ModelUtility._add<T>(_models, _pathOf, model);

  @override
  Future<List<T>> pullAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility._pullAll<T>(
          selectChildModelCollectionByType(_models)!.collection,
          _models,
          query);

  @override
  Stream<List<T>> streamAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility._streamAll<T>(
          selectChildModelCollectionByType(_models)!.collection,
          _models,
          query);

  @override
  Future<int> count<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility._count<T>(
          selectChildModelCollectionByType(_models)!.collection,
          _models,
          query);

  T modelForPath<T extends ModelCrud>(String realPath) {
    List<String> segments = realPath.split("/");
    List<(String, String)> components = List.generate(
        segments.length ~/ 2, (i) => (segments[i * 2], segments[i * 2 + 1]));

    ModelCrud? crud;
    for (ChildModel i in _models) {
      if (i.collection == components.first.$1) {
        crud = i.cloneWithPath("${i.collection}/${components.first.$2}");
        components.removeAt(0);
        break;
      }
    }

    if (crud == null) {
      throw Exception(
          "No model found for path $realPath (couldn't find a root collection: ${components.first.$1})");
    }

    for ((String, String) i in components) {
      crud = crud!.modelInCollection(i.$1, i.$2);
    }

    return crud as T;
  }
}

mixin ModelCrud implements ModelAccessor {
  String? documentPath;
  String? get documentId => documentPath?.split("/").last;
  String? get parentDocumentPath =>
      documentPath?.split("/").reversed.skip(2).reversed().join("/");
  String? get parentDocumentId => parentDocumentPath?.split("/").last;
  String? get parentCollectionPath =>
      documentPath?.split("/").reversed.skip(1).reversed().join("/");
  List<ChildModel> get childModels;

  @override
  List<ChildModel> get _models => childModels;

  @override
  String _pathOf(ChildModel c, [String? id]) =>
      "$documentPath/${c.collection}/${id ?? c.exclusiveDocumentId}";

  @override
  CollectionWalker<T> walk<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility._walk<T>(parentCollectionPath!, _models, query);

  @override
  T model<T extends ModelCrud>([String? id]) =>
      ModelUtility._model<T>(_models, _pathOf, id);

  @override
  T modelInCollection<T extends ModelCrud>(String collection, [String? id]) =>
      ModelUtility._modelInCollection<T>(_models, _pathOf, collection, id);

  @override
  Future<T?> pull<T extends ModelCrud>([String? id]) =>
      ModelUtility._pull<T>(_models, _pathOf, id);

  @override
  Future<void> push<T extends ModelCrud>(T model, [String? id]) =>
      ModelUtility._push<T>(_models, _pathOf, model, id);

  @override
  Future<void> delete<T extends ModelCrud>(T model, [String? id]) =>
      ModelUtility._delete<T>(_models, _pathOf, model, id);

  @override
  Future<void> pushAtomic<T extends ModelCrud>(T Function(T? data) txn,
          [String? id]) =>
      ModelUtility._pushAtomic<T>(_models, _pathOf, txn, id);

  @override
  Stream<T> stream<T extends ModelCrud>([String? id]) =>
      ModelUtility._stream<T>(_models, _pathOf, id);

  @override
  Future<T> add<T extends ModelCrud>(T model) =>
      ModelUtility._add<T>(_models, _pathOf, model);

  @override
  Future<List<T>> pullAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility._pullAll<T>(parentCollectionPath!, _models, query);

  @override
  Stream<List<T>> streamAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility._streamAll<T>(parentCollectionPath!, _models, query);

  @override
  Future<int> count<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility._count<T>(parentCollectionPath!, _models, query);

  T parentModel<T extends ModelCrud>() =>
      FireCrud.instance().modelForPath(parentDocumentPath!);
}
