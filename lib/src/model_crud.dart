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

  FireModel<T> getCrud<T extends ModelCrud>() =>
      FireCrud.instance().typeModels[T == ModelCrud ? runtimeType : T]!
          as FireModel<T>;

  bool get isRoot =>
      FireCrud.instance().models.any((e) => e.model.runtimeType == runtimeType);

  @override
  String $pathOf(FireModel c, [String? id]) =>
      "$documentPath/${c.collection}/${id ?? c.exclusiveDocumentId}";

  @override
  CollectionWalker<T> walk<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.walk<T>(
          "$documentPath/${ModelUtility.selectChildModelCollectionByType<T>($models)!.collection}",
          $models,
          query);

  @override
  CollectionViewer<T> view<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.view<T>(
          "$documentPath/${ModelUtility.selectChildModelCollectionByType<T>($models)!.collection}",
          $models,
          query);

  @override
  T model<T extends ModelCrud>([String? id]) =>
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
  Future<T> add<T extends ModelCrud>(T model) => ModelUtility.add<T>(
      "$documentPath/${ModelUtility.selectChildModelCollectionByType<T>($models)!.collection}",
      $models,
      $pathOf,
      model);

  @override
  Future<List<T>> getAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.pullAll<T>(
          "$documentPath/${ModelUtility.selectChildModelCollectionByType<T>($models)!.collection}",
          $models,
          query);

  @override
  Stream<List<T>> streamAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.streamAll<T>(
          "$documentPath/${ModelUtility.selectChildModelCollectionByType<T>($models)!.collection}",
          $models,
          query);

  @override
  Future<int> count<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.count<T>(
          "$documentPath/${ModelUtility.selectChildModelCollectionByType($models)!.collection}",
          $models,
          query);

  /// Returns a list of parents up a tree to the root model excluding this model
  /// The first entry in this list is the parent of this model
  /// The last entry is a root model
  /// This list is empty if this already is a root model
  Iterable<ModelCrud> parentModelPath() sync* {
    if (!hasParent) {
      return;
    }

    yield parentModel();
    yield* parentModel<ModelCrud>().parentModelPath();
  }

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
  T? findModel<T extends ModelCrud>() {
    if (runtimeType == T) {
      return this as T;
    }

    T? t;
    for (FireModel i in $models) {
      t = i.model.findModel<T>();

      if (t != null) {
        return t;
      }
    }

    return null;
  }

  Type get parentModelType => FireCrud.instance()
      .modelForPath(parentDocumentPath ?? getCrud().parentTemplatePath)
      .runtimeType;

  T parentModel<T extends ModelCrud>() => FireCrud.instance()
      .modelForPath(parentDocumentPath ?? getCrud().parentTemplatePath);

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
    return FirestoreDatabase.instance
        .document(documentPath!)
        .set(getCrud<T>().toMap(self));
  }

  @override
  Stream<T> streamSelf<T extends ModelCrud>() => FirestoreDatabase.instance
      .document(documentPath!)
      .stream
      .map((event) => (event.data == null
          ? this
          : getCrud<T>().withPath(event.data, documentPath!)) as T);

  @override
  Future<void> update<T extends ModelCrud>(
          String id, Map<String, dynamic> updates) =>
      ModelUtility.update<T>($models, $pathOf, updates, id);

  @override
  Future<void> setIfAbsent<T extends ModelCrud>(String id, T model) =>
      exists(id).then((v) => v ? Future.value() : set<T>(id, model));

  @override
  Future<void> setIfAbsentUnique<T extends ModelCrud>(T model) =>
      existsUnique<T>().then((v) => v ? Future.value() : setUnique<T>(model));

  @override
  Future<void> updateUnique<T extends ModelCrud>(
          Map<String, dynamic> updates) =>
      ModelUtility.update<T>($models, $pathOf, updates, null);

  @override
  Future<T?> getSelf<T extends ModelCrud>() async {
    if (documentPath == null) {
      throw Exception("Cannot get self without a document path");
    }

    return getCrud<T>().fromMap(
        (await FirestoreDatabase.instance.document(documentPath!).get()).data ??
            {})
      ..documentPath = documentPath;
  }

  @override
  Future<void> deleteSelf<T extends ModelCrud>() {
    if (documentPath == null) {
      throw Exception("Cannot delete self without a document path");
    }
    return FirestoreDatabase.instance.document(documentPath!).delete();
  }

  bool get hasParent => getCrud().templatePath.split("/").length > 2;

  @override
  Future<bool> exists<T extends ModelCrud>(String id) =>
      get<T>(id).then((value) => value != null).catchError((e) => false);

  @override
  Future<bool> existsUnique<T extends ModelCrud>() =>
      getUnique<T>().then((value) => value != null).catchError((e) => false);

  @override
  Future<T?> getCached<T extends ModelCrud>(String id) =>
      ModelUtility.pullCached<T>($models, $pathOf, id);

  @override
  Future<T?> getCachedUnique<T extends ModelCrud>() =>
      ModelUtility.pullCached<T>($models, $pathOf, null);

  @override
  Future<void> setSelfAtomic<T extends ModelCrud>(T Function(T? data) txn) =>
      FirestoreDatabase.instance.document(documentPath!).setAtomic((data) =>
          getCrud<T>()
              .toMap(txn(data == null ? null : getCrud<T>().fromMap(data))));
}
