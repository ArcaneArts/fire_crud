import 'package:collection_walker/collection_walker.dart';
import 'package:fire_api/fire_api.dart';
import 'package:fire_crud/fire_crud.dart';
import 'package:toxic/extensions/iterable.dart';

class ModelUtility {
  static ChildModel<T>? selectChildModel<T extends ModelCrud>(
      List<ChildModel> models,
      [String? id]) {
    return models
        .whereType<ChildModel<T>>()
        .select((e) => (e.exclusiveDocumentId != null) != (id != null));
  }

  static ChildModel<T>? selectChildModelByCollection<T extends ModelCrud>(
      List<ChildModel> models, String collection,
      [String? id]) {
    return models.where((e) => e.collection == collection) as ChildModel<T>;
  }

  static ChildModel<T>? selectChildModelCollectionByType<T extends ModelCrud>(
      List<ChildModel> models) {
    return models
        .whereType<ChildModel<T>>()
        .select((e) => e.exclusiveDocumentId == null);
  }

  static CollectionViewer<T> view<T extends ModelCrud>(
      String collectionPath, List<ChildModel> models,
      [CollectionReference Function(CollectionReference ref)? query]) {
    ChildModel<T> c = selectChildModelCollectionByType(models)!;
    return CollectionViewer<T>(
      crud: c,
      query: query,
    );
  }

  static CollectionWalker<T> walk<T extends ModelCrud>(
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

  static Future<List<T>> pullAll<T extends ModelCrud>(
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

  static Stream<List<T>> streamAll<T extends ModelCrud>(
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

  static Future<int> count<T extends ModelCrud>(
      String collectionPath, List<ChildModel> models,
      [CollectionReference Function(CollectionReference ref)? query]) {
    return (query
                ?.call(FirestoreDatabase.instance.collection(collectionPath)) ??
            FirestoreDatabase.instance.collection(collectionPath))
        .count();
  }

  static T model<T extends ModelCrud>(List<ChildModel> models,
      String Function(ChildModel c, [String? id]) pathOf,
      [String? id]) {
    ChildModel<T> c = selectChildModel<T>(models, id)!;
    return c.cloneWithPath(pathOf(c, id));
  }

  static T modelInCollection<T extends ModelCrud>(List<ChildModel> models,
      String Function(ChildModel c, [String? id]) pathOf, String collection,
      [String? id]) {
    ChildModel<T> c = selectChildModelByCollection<T>(models, collection, id)!;
    return c.cloneWithPath(pathOf(c, id));
  }

  static Future<T?> pull<T extends ModelCrud>(List<ChildModel> models,
      String Function(ChildModel c, [String? id]) pathOf,
      [String? id]) async {
    ChildModel<T> c = selectChildModel<T>(models, id)!;
    DocumentReference ref = FirestoreDatabase.instance.document(pathOf(c, id));
    return c.withPath((await ref.get()).data, ref.path);
  }

  static Future<void> push<T extends ModelCrud>(List<ChildModel> models,
      String Function(ChildModel c, [String? id]) pathOf, T model,
      [String? id]) async {
    ChildModel<T> c = selectChildModel<T>(models)!;
    await FirestoreDatabase.instance
        .document(pathOf(c, id))
        .set(c.toMap(model));
  }

  static Future<void> delete<T extends ModelCrud>(List<ChildModel> models,
      String Function(ChildModel c, [String? id]) pathOf, T model,
      [String? id]) async {
    ChildModel<T> c = selectChildModel<T>(models)!;
    await FirestoreDatabase.instance.document(pathOf(c, id)).delete();
  }

  static Future<void> pushAtomic<T extends ModelCrud>(
      List<ChildModel> models,
      String Function(ChildModel c, [String? id]) pathOf,
      T Function(T? data) txn,
      [String? id]) async {
    ChildModel<T> c = selectChildModel<T>(models)!;
    await FirestoreDatabase.instance.document(pathOf(c, id)).setAtomic(
        (data) => c.toMap(txn(data == null ? null : c.fromMap(data))));
  }

  static Stream<T> stream<T extends ModelCrud>(List<ChildModel> models,
      String Function(ChildModel c, [String? id]) pathOf,
      [String? id]) {
    ChildModel<T> c = selectChildModel<T>(models, id)!;
    return FirestoreDatabase.instance
        .document(pathOf(c, id))
        .stream
        .map((event) => c.withPath(event.data, event.reference.path)!);
  }

  static Future<T> add<T extends ModelCrud>(List<ChildModel> models,
      String Function(ChildModel c, [String? id]) pathOf, T model) async {
    ChildModel<T> c = selectChildModel<T>(models)!;
    DocumentReference r = await FirestoreDatabase.instance
        .collection(c.collection)
        .add(c.toMap(model));
    return c.cloneWithPath(pathOf(c, r.path));
  }
}
