import 'package:collection_walker/collection_walker.dart';
import 'package:fire_api/fire_api.dart';
import 'package:fire_crud/fire_crud.dart';

abstract class ModelAccessor {
  List<FireModel> get $models;

  String $pathOf(FireModel c, [String? id]);

  /// Creates a [CollectionWalker] for the given model type which should be a child collection of THIS document.
  CollectionWalker<T> walk<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  /// Creates a [CollectionViewer] for the given model type which should be a child collection of THIS document.
  CollectionViewer<T> view<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  /// Gets a child model type in a subcollection of this document. The type determines what the subcollection actually is.
  T model<T extends ModelCrud>(String id);

  T modelUnique<T extends ModelCrud>();

  T modelInCollection<T extends ModelCrud>(String collection, [String? id]);

  Future<bool> exists<T extends ModelCrud>(String id);

  Future<bool> existsUnique<T extends ModelCrud>();

  Future<T?> get<T extends ModelCrud>(String id);

  Future<T?> getUnique<T extends ModelCrud>();

  Future<T?> getCached<T extends ModelCrud>(String id);

  Future<T?> getCachedUnique<T extends ModelCrud>();

  Future<T> ensureExists<T extends ModelCrud>(String id, T model);

  Future<T> ensureExistsUnique<T extends ModelCrud>(T model);

  Future<void> setIfAbsent<T extends ModelCrud>(String id, T model);

  Future<void> setIfAbsentUnique<T extends ModelCrud>(T model);

  Future<void> setSelf<T extends ModelCrud>(T self);

  Future<void> setSelfAtomic<T extends ModelCrud>(T Function(T? data) txn);

  Future<void> set<T extends ModelCrud>(String id, T model);

  Stream<T> streamSelf<T extends ModelCrud>();

  Future<void> update<T extends ModelCrud>(
      String id, Map<String, dynamic> updates);

  Future<void> updateUnique<T extends ModelCrud>(Map<String, dynamic> updates);

  Future<void> deleteSelf<T extends ModelCrud>();

  Future<void> setAtomic<T extends ModelCrud>(
      String id, T Function(T? data) txn);

  Future<void> setUnique<T extends ModelCrud>(T model);

  Future<void> setUniqueAtomic<T extends ModelCrud>(T Function(T? data) txn);

  Future<void> delete<T extends ModelCrud>(String id);

  Future<void> deleteUnique<T extends ModelCrud>();

  Stream<T?> stream<T extends ModelCrud>(String id);

  Stream<T?> streamUnique<T extends ModelCrud>();

  Future<T> add<T extends ModelCrud>(T model);

  Future<List<T>> getAll<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  Stream<List<T>> streamAll<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  Future<int> count<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);
}
