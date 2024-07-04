import 'package:collection_walker/collection_walker.dart';
import 'package:fire_api/fire_api.dart';
import 'package:fire_crud/fire_crud.dart';

abstract class ModelAccessor {
  List<FireModel> get $models;

  String $pathOf(FireModel c, [String? id]);

  CollectionWalker<T> walk<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  CollectionViewer<T> view<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  T model<T extends ModelCrud>(String id);

  T modelUnique<T extends ModelCrud>();

  T modelInCollection<T extends ModelCrud>(String collection, [String? id]);

  Future<T?> get<T extends ModelCrud>(String id);

  Future<T?> getUnique<T extends ModelCrud>();

  Future<T> ensureExists<T extends ModelCrud>(String id, T model);

  Future<T> ensureExistsUnique<T extends ModelCrud>(T model);

  Future<void> set<T extends ModelCrud>(String id, T model);

  Future<void> setAtomic<T extends ModelCrud>(
      String id, T Function(T? data) txn);

  Future<void> setUnique<T extends ModelCrud>(T model);

  Future<void> setUniqueAtomic<T extends ModelCrud>(T Function(T? data) txn);

  Future<void> delete<T extends ModelCrud>(String id);

  Future<void> deleteUnique<T extends ModelCrud>();

  Stream<T?> stream<T extends ModelCrud>(String id);

  Stream<T?> streamUnique<T extends ModelCrud>();

  Future<T> add<T extends ModelCrud>(T model);

  Future<List<T>> pullAll<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  Stream<List<T>> streamAll<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  Future<int> count<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);
}
