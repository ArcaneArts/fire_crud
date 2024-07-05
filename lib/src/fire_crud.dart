import 'package:collection_walker/collection_walker.dart';
import 'package:fire_api/fire_api.dart';
import 'package:fire_crud/fire_crud.dart';

FireCrud get $crud => FireCrud.instance();

/// A class that provides CRUD operations for Firestore.
class FireCrud extends ModelAccessor {
  static FireCrud? _instance;
  Map<Type, FireModel> typeModels = {};

  FireCrud._();

  factory FireCrud.instance() => _instance ??= FireCrud._();

  List<FireModel> models = [];

  void registerModel(FireModel root) {
    models.add(root);
    typeModels[root.model.runtimeType] = root;
    root.registerTypeModels();
  }

  @override
  CollectionWalker<T> walk<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.walk<T>(
          ModelUtility.selectChildModelCollectionByType($models)!.collection,
          $models,
          query);

  @override
  CollectionViewer<T> view<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.view<T>(
          ModelUtility.selectChildModelCollectionByType($models)!.collection,
          $models,
          query);

  @override
  String $pathOf(FireModel c, [String? id]) =>
      "${c.collection}/${id ?? c.exclusiveDocumentId}";

  @override
  List<FireModel<ModelCrud>> get $models => models;

  @override
  T model<T extends ModelCrud>(String id) =>
      ModelUtility.model<T>($models, $pathOf, id);

  @override
  T modelUnique<T extends ModelCrud>() =>
      ModelUtility.model<T>($models, $pathOf, null);

  @override
  T modelInCollection<T extends ModelCrud>(String collection, [String? id]) =>
      ModelUtility.modelInCollection<T>($models, $pathOf, collection, id);

  @override
  Future<T> ensureExists<T extends ModelCrud>(String id, T model) async {
    T? t = await get<T>(id);
    if (t == null) {
      await set<T>(id, model);
      return model;
    }

    return t;
  }

  @override
  Future<T> ensureExistsUnique<T extends ModelCrud>(T model) async {
    T? t = await getUnique<T>();
    if (t == null) {
      await setUnique<T>(model);
      return model;
    }

    return t;
  }

  @override
  Future<void> delete<T extends ModelCrud>(String id) =>
      ModelUtility.delete<T>($models, $pathOf, id);

  @override
  Future<void> deleteUnique<T extends ModelCrud>() =>
      ModelUtility.delete<T>($models, $pathOf, null);

  @override
  Stream<T?> stream<T extends ModelCrud>(String id) =>
      ModelUtility.stream<T>($models, $pathOf, id);

  @override
  Stream<T?> streamUnique<T extends ModelCrud>() =>
      ModelUtility.stream<T>($models, $pathOf, null);

  @override
  Future<T> add<T extends ModelCrud>(T model) => ModelUtility.add<T>(
      ModelUtility.selectChildModelCollectionByType($models)!.collection,
      $models,
      $pathOf,
      model);

  @override
  Future<List<T>> pullAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.pullAll<T>(
          ModelUtility.selectChildModelCollectionByType($models)!.collection,
          $models,
          query);

  @override
  Stream<List<T>> streamAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.streamAll<T>(
          ModelUtility.selectChildModelCollectionByType($models)!.collection,
          $models,
          query);

  @override
  Future<int> count<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.count<T>(
          ModelUtility.selectChildModelCollectionByType($models)!.collection,
          $models,
          query);

  T modelForPath<T extends ModelCrud>(String realPath) {
    List<String> segments = realPath.split("/");
    List<(String, String)> components = List.generate(
        segments.length ~/ 2, (i) => (segments[i * 2], segments[i * 2 + 1]));

    ModelCrud? crud;
    for (FireModel i in $models) {
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

  @override
  Future<T?> get<T extends ModelCrud>(String id) =>
      ModelUtility.pull<T>($models, $pathOf, id);

  @override
  Future<T?> getUnique<T extends ModelCrud>() =>
      ModelUtility.pull<T>($models, $pathOf, null);

  @override
  Future<void> set<T extends ModelCrud>(String id, T model) =>
      ModelUtility.push<T>($models, $pathOf, model, id);

  @override
  Future<void> setUnique<T extends ModelCrud>(T model) =>
      ModelUtility.push<T>($models, $pathOf, model, null);

  @override
  Future<void> setAtomic<T extends ModelCrud>(
          String id, T Function(T? data) txn) =>
      ModelUtility.pushAtomic<T>($models, $pathOf, txn, id);

  @override
  Future<void> setUniqueAtomic<T extends ModelCrud>(T Function(T? data) txn) =>
      ModelUtility.pushAtomic<T>($models, $pathOf, txn, null);

  @override
  Future<void> setSelf<T extends ModelCrud>(T self) {
    throw Exception("setSelf is not supported on the root accessor");
  }

  @override
  Future<void> setSelfAtomic<T extends ModelCrud>(T Function(T? data) txn) {
    throw Exception("setSelfAtomic is not supported on the root accessor");
  }
}
