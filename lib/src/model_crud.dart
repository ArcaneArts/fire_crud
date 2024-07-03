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
  List<ChildModel> get childModels;

  @override
  List<ChildModel> get $models => childModels;

  ChildModel get crud => FireCrud.instance().typeModels[runtimeType]!;

  bool get isRoot =>
      FireCrud.instance().models.any((e) => e.model.runtimeType == runtimeType);

  @override
  String $pathOf(ChildModel c, [String? id]) =>
      "$documentPath/${c.collection}/${id ?? c.exclusiveDocumentId}";

  @override
  CollectionWalker<T> walk<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.walk<T>(parentCollectionPath!, $models, query);

  @override
  CollectionViewer<T> view<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.view<T>(parentCollectionPath!, $models, query);

  @override
  T model<T extends ModelCrud>([String? id]) =>
      ModelUtility.model<T>($models, $pathOf, id);

  @override
  T modelInCollection<T extends ModelCrud>(String collection, [String? id]) =>
      ModelUtility.modelInCollection<T>($models, $pathOf, collection, id);

  @override
  Future<T?> pull<T extends ModelCrud>([String? id]) =>
      ModelUtility.pull<T>($models, $pathOf, id);

  @override
  Future<void> push<T extends ModelCrud>(T model, [String? id]) =>
      ModelUtility.push<T>($models, $pathOf, model, id);

  @override
  Future<void> delete<T extends ModelCrud>(T model, [String? id]) =>
      ModelUtility.delete<T>($models, $pathOf, model, id);

  @override
  Future<void> pushAtomic<T extends ModelCrud>(T Function(T? data) txn,
          [String? id]) =>
      ModelUtility.pushAtomic<T>($models, $pathOf, txn, id);

  @override
  Stream<T> stream<T extends ModelCrud>([String? id]) =>
      ModelUtility.stream<T>($models, $pathOf, id);

  @override
  Future<T> add<T extends ModelCrud>(T model) =>
      ModelUtility.add<T>($models, $pathOf, model);

  @override
  Future<List<T>> pullAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.pullAll<T>(parentCollectionPath!, $models, query);

  @override
  Stream<List<T>> streamAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.streamAll<T>(parentCollectionPath!, $models, query);

  @override
  Future<int> count<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.count<T>(parentCollectionPath!, $models, query);

  T parentModel<T extends ModelCrud>() =>
      FireCrud.instance().modelForPath(parentDocumentPath!);
}
