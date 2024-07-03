import 'package:collection_walker/collection_walker.dart';
import 'package:fire_api/fire_api.dart';
import 'package:fire_crud/fire_crud.dart';

abstract class ModelAccessor {
  List<ChildModel> get $models;

  String $pathOf(ChildModel c, [String? id]);

  CollectionWalker<T> walk<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  CollectionViewer<T> view<T extends ModelCrud>(
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
