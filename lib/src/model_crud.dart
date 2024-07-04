import 'package:collection_walker/collection_walker.dart';
import 'package:fire_api/fire_api.dart';
import 'package:fire_crud/fire_crud.dart';
import 'package:toxic/extensions/iterable.dart';

mixin ModelCrud implements ModelAccessor {
  String? documentPath;
  String? get documentId => documentPath?.split("/").last;
  String? get parentDocumentPath =>
      documentPath?.split("/").reversed.skip(2).reversed().join("/");
  String? get parentDocumentId => parentDocumentPath?.split("/").last;
  String? get parentCollectionPath =>
      documentPath?.split("/").reversed.skip(1).reversed().join("/");
  List<FireModel> get childModels;

  @override
  List<FireModel> get $models => childModels;

  FireModel get crud => FireCrud.instance().typeModels[runtimeType]!;

  bool get isRoot =>
      FireCrud.instance().models.any((e) => e.model.runtimeType == runtimeType);

  @override
  String $pathOf(FireModel c, [String? id]) =>
      "$documentPath/${c.collection}/${id ?? c.exclusiveDocumentId}";

  @override
  CollectionWalker<T> walk<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.walk<T>(
          "$documentPath/${ModelUtility.selectChildModelCollectionByType($models)!.collection}",
          $models,
          query);

  @override
  CollectionViewer<T> view<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.view<T>(
          "$documentPath/${ModelUtility.selectChildModelCollectionByType($models)!.collection}",
          $models,
          query);

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
  Future<T> add<T extends ModelCrud>(T model) =>
      ModelUtility.add<T>($models, $pathOf, model);

  @override
  Future<List<T>> pullAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.pullAll<T>(
          "$documentPath/${ModelUtility.selectChildModelCollectionByType($models)!.collection}",
          $models,
          query);

  @override
  Stream<List<T>> streamAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.streamAll<T>(
          "$documentPath/${ModelUtility.selectChildModelCollectionByType($models)!.collection}",
          $models,
          query);

  @override
  Future<int> count<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.count<T>(
          "$documentPath/${ModelUtility.selectChildModelCollectionByType($models)!.collection}",
          $models,
          query);

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

  T parentModel<T extends ModelCrud>() =>
      FireCrud.instance().modelForPath(parentDocumentPath!);

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
}
