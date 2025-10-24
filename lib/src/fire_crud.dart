import 'package:collection_walker/collection_walker.dart';
import 'package:fire_api/fire_api.dart';
import 'package:fire_crud/fire_crud.dart';

/// Provides global access to the singleton instance of [RootFireCrud], which serves as the entry point for CRUD operations in the fire_crud package.
RootFireCrud get $crud => RootFireCrud.instance();

/// Singleton wrapper class for [FireCrud] that provides the root instance for the fire_crud package.
///
/// [RootFireCrud] ensures a single, globally accessible instance of the CRUD operations manager, facilitating centralized management of Firestore models and their interactions.
/// Key features include lazy initialization and extension of [FireCrud]'s core functionality without additional configuration.
class RootFireCrud extends FireCrud {
  static RootFireCrud? _instance;
  RootFireCrud._() : super._();
  factory RootFireCrud.instance() => _instance ??= RootFireCrud._();
}

/// Core class in the fire_crud package that provides comprehensive CRUD (Create, Read, Update, Delete) operations for Firestore models.
///
/// [FireCrud] extends [ModelAccessor] to manage [FireModel] instances, handle document paths, and perform database interactions via Firestore.
/// It supports registering models, querying collections, pagination, and atomic updates, making it the central hub for model-based data persistence.
/// Key features include type-safe model selection, streaming support, and utility methods for common operations like ensuring document existence.
class FireCrud extends ModelAccessor {
  static FireCrud? _instance;

  /// Map of model types to their corresponding [FireModel] instances, enabling quick lookup and type-safe access to CRUD operations for specific model classes.
  Map<Type, FireModel> typeModels = {};

  /// Private constructor for [FireCrud] to enforce singleton pattern and prevent direct instantiation.
  ///
  /// Initializes the instance with empty model lists and type mappings, preparing it for registration of [FireModel]s.
  FireCrud._();

  /// Factory constructor that returns the singleton instance of [RootFireCrud], ensuring global access to CRUD operations.
  ///
  /// If no instance exists, it creates and caches the [RootFireCrud] singleton; otherwise, it reuses the existing one.
  factory FireCrud.instance() => RootFireCrud._instance ??= RootFireCrud._();

  /// List of all registered [FireModel] instances, used for iterating over available models and performing collection-wide operations.
  List<FireModel> models = [];

  /// Retrieves the [FireModel] responsible for a given document path by matching path segments against registered model templates.
  ///
  /// @param path The Firestore document path to match (e.g., "collection/documentId").
  /// @return The matching [FireModel], or null if no model corresponds to the path.
  /// Throws no exceptions but may return null for unmatched paths.
  FireModel? getCrudForDocumentPath(String path) {
    List<String> segments = path.split("/");

    searching:
    for (FireModel i in typeModels.values) {
      List<String> iSegments = i.templatePath.split("/");

      if (iSegments.length != segments.length) {
        continue;
      }

      for (int j = 0; j < iSegments.length; j += 2) {
        if (iSegments[j] != segments[j]) {
          continue searching;
        }

        if (j == iSegments.length - 2) {
          return i;
        }
      }
    }

    return null;
  }

  /// Registers artifact serialization functions for converting between model objects and Firestore maps.
  ///
  /// This method sets up the global artifact handlers used by all [FireModel]s for data persistence.
  /// @param artifactFromMap Function to deserialize a Firestore map into a model instance.
  /// @param artifactToMap Function to serialize a model instance into a Firestore map.
  /// @param artifactConstruct Function to create an empty model instance.
  /// No return value; side effect is updating internal artifact configuration.
  void setupArtifact(
    T Function<T>(Map<String, dynamic> m) artifactFromMap,
    Map<String, dynamic> Function(Object o) artifactToMap,
    T Function<T>() artifactConstruct,
  ) =>
      $registerFCA(artifactFromMap, artifactToMap, artifactConstruct);

  /// Registers a list of [FireModel] instances with the [FireCrud] manager.
  ///
  /// Iterates over the provided models and calls [registerModel] for each, updating the internal models list and type mappings.
  /// @param models List of [FireModel]s to register.
  /// No return value; side effect is populating the CRUD registry for future operations.
  void registerModels(List<FireModel> models) {
    for (FireModel i in models) {
      registerModel(i);
    }
  }

  /// Registers a single [FireModel] instance, configuring its template path and sub-models.
  ///
  /// Adds the model to the internal lists, sets its template path based on collection and type, and recursively registers any child type models.
  /// @param root The [FireModel] to register.
  /// No return value; side effect is enabling CRUD operations for the model's type.
  void registerModel(FireModel root) {
    models.add(root);
    typeModels[root.model.runtimeType] = root;
    root.templatePath = "${root.collection}/\$${root.model.runtimeType}.id";
    root.registerTypeModels();
  }

  @override
  CollectionWalker<T> walk<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.walk<T>(
          ModelUtility.selectChildModelCollectionByType<T>($models)!.collection,
          $models,
          query);

  @override
  CollectionViewer<T> view<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.view<T>(
          ModelUtility.selectChildModelCollectionByType<T>($models)!.collection,
          $models,
          query);

  @override
  String $pathOf(FireModel c, [String? id]) =>
      "${c.collection}/${id ?? c.exclusiveDocumentId}";

  @override
  List<FireModel<ModelCrud>> get $models => models;

  @override
  T $model<T extends ModelCrud>([String? id]) =>
      ModelUtility.model<T>($models, $pathOf, id);

  @override
  T modelUnique<T extends ModelCrud>() =>
      ModelUtility.model<T>($models, $pathOf, null);

  @override
  T modelInCollection<T extends ModelCrud>(String collection, [String? id]) =>
      ModelUtility.modelInCollection<T>($models, $pathOf, collection, id);

  /// Ensures a document for the specified model type and ID exists in Firestore, creating it if necessary.
  ///
  /// First attempts to retrieve the document; if not found, sets the provided model and returns it.
  /// @param id The document ID.
  /// @param model The model instance to create if absent.
  /// @return The existing or newly created model instance.
  /// May throw Firestore exceptions on I/O errors.
  @override
  Future<T> $ensureExists<T extends ModelCrud>(String id, T model) async {
    T? t = await $get<T>(id);
    if (t == null) {
      await $set<T>(id, model);
      return model;
    }

    return t;
  }

  /// Ensures a unique document for the specified model type exists in Firestore, creating it if necessary.
  ///
  /// Similar to [$ensureExists], but uses null ID for unique documents without explicit IDs.
  /// @param model The model instance to create if absent.
  /// @return The existing or newly created model instance.
  /// May throw Firestore exceptions on I/O errors.
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
  Future<void> $delete<T extends ModelCrud>(String id) =>
      ModelUtility.delete<T>($models, $pathOf, id);

  @override
  Future<void> deleteUnique<T extends ModelCrud>() =>
      ModelUtility.delete<T>($models, $pathOf, null);

  @override
  Stream<T?> $stream<T extends ModelCrud>(String id) =>
      ModelUtility.stream<T>($models, $pathOf, id);

  @override
  Stream<T?> streamUnique<T extends ModelCrud>() =>
      ModelUtility.stream<T>($models, $pathOf, null);

  /// Adds a new document for the specified model to its collection, generating an auto-ID.
  ///
  /// Uses the model's collection reference and persists the model data via Firestore.
  /// @param model The model instance to add.
  /// @return A Future completing with the added model (updated with the generated ID).
  /// May throw Firestore exceptions on I/O errors.
  @override
  Future<T> $add<T extends ModelCrud>(T model, {bool useULID = false}) =>
      ModelUtility.add<T>(
          ModelUtility.selectChildModelCollectionByType<T>($models)!.collection,
          $models,
          $pathOf,
          model,
          useULID: useULID);

  /// Deletes all documents in the collection for the specified model type, optionally filtered by a query.
  ///
  /// Performs a batched deletion of matching documents.
  /// @param query Optional query builder for filtering documents to delete.
  /// No return value; side effect is removal of documents from Firestore.
  /// May throw Firestore exceptions on I/O errors.
  @override
  Future<void> deleteAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.deleteAll<T>(
          ModelUtility.selectChildModelCollectionByType<T>($models)!.collection,
          $models,
          query);

  /// Retrieves a paginated result set from the collection for the specified model type.
  ///
  /// Supports custom queries, page size, and direction for efficient data retrieval in UI components.
  /// @param pageSize Number of documents per page (default: 50).
  /// @param reversed Whether to reverse the query order (default: false).
  /// @param query Optional query builder for filtering.
  /// @return A Future with the [ModelPage] containing documents and pagination token, or null if no results.
  /// May throw Firestore exceptions on I/O errors.
  Future<ModelPage<T>?> paginate<T extends ModelCrud>({
    int pageSize = 50,
    bool reversed = false,
    CollectionReference Function(CollectionReference ref)? query,
  }) =>
      ModelUtility.pullPage<T>(
          collectionPath:
              ModelUtility.selectChildModelCollectionByType<T>($models)!
                  .collection,
          models: $models,
          query: query,
          pageSize: pageSize,
          reversed: reversed);

  @override
  Future<List<T>> getAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.pullAll<T>(
          ModelUtility.selectChildModelCollectionByType<T>($models)!.collection,
          $models,
          query);

  @override
  Stream<List<T>> streamAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.streamAll<T>(
          ModelUtility.selectChildModelCollectionByType<T>($models)!.collection,
          $models,
          query);

  @override
  Future<int> $count<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.count<T>(
          ModelUtility.selectChildModelCollectionByType<T>($models)!.collection,
          $models,
          query);

  /// Constructs a [ModelCrud] instance by parsing a real Firestore path and navigating nested collections.
  ///
  /// Matches the path against registered models to build a nested model accessor.
  /// @param realPath The full Firestore path (e.g., "parent/child/docId").
  /// @return The constructed [ModelCrud] for the path.
  /// Throws an [Exception] if no root collection matches.
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
  Future<T?> $get<T extends ModelCrud>(String id) =>
      ModelUtility.pull<T>($models, $pathOf, id);

  @override
  Future<T?> getUnique<T extends ModelCrud>() =>
      ModelUtility.pull<T>($models, $pathOf, null);

  @override
  Future<void> $set<T extends ModelCrud>(String id, T model) =>
      ModelUtility.push<T>($models, $pathOf, model, id);

  @override
  Future<void> $update<T extends ModelCrud>(
          String id, Map<String, dynamic> updates) =>
      ModelUtility.update<T>($models, $pathOf, updates, id);

  @override
  Future<void> updateUnique<T extends ModelCrud>(
          Map<String, dynamic> updates) =>
      ModelUtility.update<T>($models, $pathOf, updates, null);

  @override
  Future<void> setUnique<T extends ModelCrud>(T model) =>
      ModelUtility.push<T>($models, $pathOf, model, null);

  @override
  Future<void> $setAtomic<T extends ModelCrud>(
          String id, T Function(T? data) txn) =>
      ModelUtility.pushAtomic<T>($models, $pathOf, txn, id);

  @override
  Future<void> setUniqueAtomic<T extends ModelCrud>(T Function(T? data) txn) =>
      ModelUtility.pushAtomic<T>($models, $pathOf, txn, null);

  @override
  Stream<T> streamSelfRaw<T extends ModelCrud>() {
    throw Exception("streamSelf is not supported on the root accessor");
  }

  @override
  Future<void> deleteSelfRaw<T extends ModelCrud>() {
    throw Exception("deleteSelf is not supported on the root accessor");
  }

  @override
  Future<void> setSelfRaw<T extends ModelCrud>(T self) {
    throw Exception("setSelf is not supported on the root accessor");
  }

  @override
  Future<void> updateSelfRaw<T extends ModelCrud>(
          Map<String, dynamic> updates) =>
      throw Future.error(
          Exception("updateSelf is not supported on the root accessor"));

  @override
  Future<void> setSelfAtomicRaw<T extends ModelCrud>(T Function(T? data) txn) {
    throw Exception("setSelfAtomic is not supported on the root accessor");
  }

  @override
  Future<T?> getSelfRaw<T extends ModelCrud>() {
    throw Exception("getSelf is not supported on the root accessor");
  }

  @override
  Future<T?> getCachedSelfRaw<T extends ModelCrud>() {
    throw Exception("getSelf is not supported on the root accessor");
  }

  /// Checks if a document for the specified model type and ID exists in Firestore.
  ///
  /// Performs a lightweight existence check without fetching the full document.
  /// @param id The document ID.
  /// @return A Future with true if the document exists, false otherwise.
  /// Catches and handles errors by returning false.
  @override
  Future<bool> $exists<T extends ModelCrud>(String id) =>
      $get<T>(id).then((value) => value != null).catchError((e) => false);

  /// Checks if the unique document for the specified model type exists in Firestore.
  ///
  /// Similar to [$exists] but for documents without explicit IDs.
  /// @return A Future with true if the document exists, false otherwise.
  /// Catches and handles errors by returning false.
  @override
  Future<bool> existsUnique<T extends ModelCrud>() =>
      getUnique<T>().then((value) => value != null).catchError((e) => false);

  @override
  Future<void> setIfAbsent<T extends ModelCrud>(String id, T model) =>
      $exists(id).then((v) => v ? Future.value() : $set<T>(id, model));

  @override
  Future<void> setIfAbsentUnique<T extends ModelCrud>(T model) =>
      existsUnique<T>().then((v) => v ? Future.value() : setUnique<T>(model));

  @override
  Future<T?> getCached<T extends ModelCrud>(String id) =>
      ModelUtility.pullCached<T>($models, $pathOf, id);

  @override
  Future<T?> getCachedUnique<T extends ModelCrud>() =>
      ModelUtility.pullCached<T>($models, $pathOf, null);

  @override
  Future<void> $change<T extends ModelCrud>(String id, T before, T after) {
    FireModel<T> c = ModelUtility.selectChildModel<T>($models)!;
    return $update<T>(
        id, ModelUtility.getUpdates(c.toMap(before), c.toMap(after)));
  }

  @override
  Future<void> changeUnique<T extends ModelCrud>(T before, T after) {
    FireModel<T> c = ModelUtility.selectChildModel<T>($models)!;
    return updateUnique<T>(
        ModelUtility.getUpdates(c.toMap(before), c.toMap(after)));
  }

  @override
  Future<void> changeSelfRaw<T extends ModelCrud>(T before, T after) =>
      throw Future.error(
          Exception("changeSelf is not supported on the root accessor"));

  @override
  Future<void> $updateAtomic<T extends ModelCrud>(
          String id, Map<String, dynamic> Function(T? initial) updater) =>
      ModelUtility.updateAtomic<T>($models, $pathOf, updater);

  @override
  Future<void> updateUniqueAtomic<T extends ModelCrud>(
          Map<String, dynamic> Function(T? initial) updater) =>
      ModelUtility.updateAtomic<T>($models, $pathOf, updater, null);

  @override
  Future<void> updateSelfAtomicRaw<T extends ModelCrud>(
          Map<String, dynamic> Function(T? initial) updater) =>
      throw Exception("updateSelfAtomic is not supported on the root accessor");

  @override
  T? findModel<T extends ModelCrud>() {
    if (typeModels.containsKey(T)) {
      return typeModels[T]!.model as T;
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
}
