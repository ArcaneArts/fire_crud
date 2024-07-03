import 'package:collection_walker/collection_walker.dart';
import 'package:fire_api/fire_api.dart';
import 'package:fire_crud/fire_crud.dart';

class FireCrud extends ModelAccessor {
  static FireCrud? _instance;
  Map<Type, ChildModel> typeModels = {};

  FireCrud._();

  factory FireCrud.instance() => _instance ??= FireCrud._();

  List<ChildModel> models = [];

  void registerModel(ChildModel root) {
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
  String $pathOf(ChildModel c, [String? id]) =>
      "${c.collection}/${id ?? c.exclusiveDocumentId}";

  @override
  List<ChildModel<ModelCrud>> get $models => models;

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
    for (ChildModel i in $models) {
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
