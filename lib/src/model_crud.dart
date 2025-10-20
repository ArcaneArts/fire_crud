import 'package:collection_walker/collection_walker.dart';
import 'package:fire_api/fire_api.dart';
import 'package:fire_crud/fire_crud.dart';
import 'package:pylon_codec/pylon_codec.dart';
import 'package:toxic/extensions/iterable.dart';

/// Mixin that provides comprehensive CRUD (Create, Read, Update, Delete) operations
/// for individual [FireModel] instances in Firestore. It implements [ModelAccessor]
/// to facilitate model access and manipulation, and [PylonCodec<ModelCrud>] for
/// serialization and deserialization of model paths. This mixin is central to the
/// fire_crud package, enabling hierarchical model management with parent-child
/// relationships, pagination, streaming, and atomic updates for robust data handling.
mixin ModelCrud implements ModelAccessor, PylonCodec<ModelCrud> {
  /// The full path to this model's document in Firestore, used as the base for
  /// all child model operations and path calculations.
  String? documentPath;

  /// Derived document ID from [documentPath], representing the last segment of the path.
  String? get documentId => documentPath?.split("/").last;

  /// Derived path to the parent document, excluding the current model and its collection.
  String? get parentDocumentPath =>
      documentPath?.split("/").reversed.skip(2).reversed().join("/");

  /// Derived ID of the parent document from [parentDocumentPath].
  String? get parentDocumentId => parentDocumentPath?.split("/").last;

  /// Derived path to the parent collection, excluding the current model's document.
  String? get parentCollectionPath =>
      documentPath?.split("/").reversed.skip(1).reversed().join("/");

  /// List of child [FireModel] instances associated with this model, used for
  /// accessing and managing nested models in the Firestore hierarchy.
  List<FireModel> get childModels;

  /// Encodes this [ModelCrud] instance to a string representation using its [documentPath].
  /// Returns the document path as the encoded value.
  ///
  /// Throws a [StateError] if [documentPath] is null.
  @override
  String pylonEncode(ModelCrud value) => value.documentPath!;

  /// Decodes a string value back into a [ModelCrud] instance by fetching the
  /// corresponding document from Firestore and constructing the model.
  ///
  /// The decoded model will have its [documentPath] set to the provided value.
  /// Returns a [Future] that completes with the decoded [ModelCrud].
  ///
  /// Throws a [FirestoreException] if the document fetch fails.
  @override
  Future<ModelCrud> pylonDecode(String value) async =>
      ((FireCrud.instance().typeModels[runtimeType]!).fromMap(
          (await FirestoreDatabase.instance.document(value).get()).data ?? {})
        ..documentPath = documentPath);

  /// Getter for child models, aliasing [childModels] for compatibility with [ModelAccessor].
  @override
  List<FireModel> get $models => childModels;

  /// Retrieves the [FireModel] instance associated with the specified type T.
  ///
  /// If T is [ModelCrud], uses the runtime type of this instance. Otherwise,
  /// looks up the model from [FireCrud]'s type registry.
  /// Returns the corresponding [FireModel<T>].
  FireModel<T> getCrud<T extends ModelCrud>() =>
      FireCrud.instance().typeModels[T == ModelCrud ? runtimeType : T]!
          as FireModel<T>;

  /// Determines if this model is a root model in the [FireCrud] hierarchy.
  ///
  /// Checks if any model in [FireCrud.instance().models] matches this runtime type.
  /// Returns true if it is a root, false otherwise.
  bool get isRoot =>
      FireCrud.instance().models.any((e) => e.model.runtimeType == runtimeType);

  /// Constructs the full Firestore path for a child model of type [FireModel] c.
  ///
  /// Appends the collection and document ID to [documentPath]. If id is provided,
  /// uses it; otherwise, uses c's [exclusiveDocumentId].
  /// Returns the complete path string.
  @override
  String $pathOf(FireModel c, [String? id]) =>
      "$documentPath/${c.collection}/${id ?? c.exclusiveDocumentId}";

  /// Creates a [CollectionWalker] for querying and iterating over child models of type T.
  ///
  /// The walker operates on the collection path derived from [documentPath] and the
  /// appropriate child model type. An optional query builder can customize the
  /// [CollectionReference].
  /// Returns a [CollectionWalker<T>] for traversal.
  @override
  CollectionWalker<T> walk<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.walk<T>(
          "$documentPath/${ModelUtility.selectChildModelCollectionByType<T>($models)!.collection}",
          $models,
          query);

  /// Creates a [CollectionViewer] for real-time streaming of child models of type T.
  ///
  /// Similar to [walk], but provides a viewer for ongoing updates. Uses the derived
  /// collection path and optional query builder.
  /// Returns a [CollectionViewer<T>] for observation.
  @override
  CollectionViewer<T> view<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.view<T>(
          "$documentPath/${ModelUtility.selectChildModelCollectionByType<T>($models)!.collection}",
          $models,
          query);

  /// Retrieves a child model instance of type T at the specified id.
  ///
  /// Uses [ModelUtility.model] to construct from the path generated by [$pathOf].
  /// Returns the [T] instance, or null if not found.
  @override
  T $model<T extends ModelCrud>([String? id]) =>
      ModelUtility.model<T>($models, $pathOf, id);

  /// Retrieves the unique child model instance of type T (no id specified).
  ///
  /// Assumes a single instance exists in the collection. Uses [ModelUtility.model]
  /// with null id.
  /// Returns the [T] instance.
  @override
  T modelUnique<T extends ModelCrud>() =>
      ModelUtility.model<T>($models, $pathOf, null);

  /// Retrieves a child model of type T from a specific collection at the given id.
  ///
  /// Allows targeting models in non-default collections. Uses [ModelUtility.modelInCollection].
  /// Returns the [T] instance, or null if not found.
  @override
  T modelInCollection<T extends ModelCrud>(String collection, [String? id]) =>
      ModelUtility.modelInCollection<T>($models, $pathOf, collection, id);

  /// Deletes a child model of type T at the specified id.
  ///
  /// Performs the deletion asynchronously via [ModelUtility.delete]. No return value.
  /// Throws a [FirestoreException] if deletion fails.
  @override
  Future<void> $delete<T extends ModelCrud>(String id) =>
      ModelUtility.delete<T>($models, $pathOf, id);

  /// Deletes the unique child model of type T (no id specified).
  ///
  /// Assumes a single instance. Uses [ModelUtility.delete] with null id.
  /// Throws a [FirestoreException] if deletion fails.
  @override
  Future<void> deleteUnique<T extends ModelCrud>() =>
      ModelUtility.delete<T>($models, $pathOf, null);

  /// Streams changes to a child model of type T at the specified id.
  ///
  /// Provides real-time updates via [ModelUtility.stream]. Returns a [Stream<T?>]
  /// that emits the model or null if deleted.
  @override
  Stream<T?> $stream<T extends ModelCrud>(String id) =>
      ModelUtility.stream<T>($models, $pathOf, id);

  /// Streams changes to the unique child model of type T.
  ///
  /// Uses null id for single-instance models. Returns a [Stream<T?>].
  @override
  Stream<T?> streamUnique<T extends ModelCrud>() =>
      ModelUtility.stream<T>($models, $pathOf, null);

  /// Adds a new child model of type T to its collection.
  ///
  /// Generates an ID and persists via [ModelUtility.add]. Returns a [Future<T>]
  /// with the added model.
  /// Throws a [FirestoreException] if addition fails.
  @override
  Future<T> $add<T extends ModelCrud>(T model) => ModelUtility.add<T>(
      "$documentPath/${ModelUtility.selectChildModelCollectionByType<T>($models)!.collection}",
      $models,
      $pathOf,
      model);

  /// Deletes all child models of type T matching the optional query.
  ///
  /// Uses [ModelUtility.deleteAll] on the derived collection path. No return value.
  /// Throws a [FirestoreException] if any deletion fails.
  @override
  Future<void> deleteAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.deleteAll<T>(
          "$documentPath/${ModelUtility.selectChildModelCollectionByType<T>($models)!.collection}",
          $models,
          query);

  /// Retrieves all child models of type T matching the optional query.
  ///
  /// Fetches via [ModelUtility.pullAll] on the derived collection. Returns a [Future<List<T>>].
  /// Throws a [FirestoreException] if fetch fails.
  @override
  Future<List<T>> getAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.pullAll<T>(
          "$documentPath/${ModelUtility.selectChildModelCollectionByType<T>($models)!.collection}",
          $models,
          query);

  /// Paginates child models of type T with configurable page size and order.
  ///
  /// Uses [ModelUtility.pullPage] on the derived collection path. Supports query builder,
  /// default pageSize of 50, and reversed ordering. Returns a [Future<ModelPage<T>?>].
  /// Throws a [FirestoreException] if pagination fails.
  Future<ModelPage<T>?> paginate<T extends ModelCrud>({
    int pageSize = 50,
    bool reversed = false,
    CollectionReference Function(CollectionReference ref)? query,
  }) =>
      ModelUtility.pullPage<T>(
          collectionPath:
              "$documentPath/${ModelUtility.selectChildModelCollectionByType<T>($models)!.collection}",
          models: $models,
          query: query,
          pageSize: pageSize,
          reversed: reversed);

  /// Streams all child models of type T matching the optional query.
  ///
  /// Provides real-time list updates via [ModelUtility.streamAll]. Returns a [Stream<List<T>>].
  @override
  Stream<List<T>> streamAll<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.streamAll<T>(
          "$documentPath/${ModelUtility.selectChildModelCollectionByType<T>($models)!.collection}",
          $models,
          query);

  /// Counts the number of child models of type T matching the optional query.
  ///
  /// Uses [ModelUtility.count] on the derived collection. Returns a [Future<int>].
  /// Throws a [FirestoreException] if count fails.
  @override
  Future<int> $count<T extends ModelCrud>(
          [CollectionReference Function(CollectionReference ref)? query]) =>
      ModelUtility.count<T>(
          "$documentPath/${ModelUtility.selectChildModelCollectionByType($models)!.collection}",
          $models,
          query);

  /// Generates an iterable of parent models up the hierarchy to the root, excluding this model.
  ///
  /// Yields from immediate parent to root [ModelCrud]. Empty if this is a root model.
  /// The first yielded is the direct parent; the last is the root.
  /// Returns a synchronous [Iterable<ModelCrud>].
  ///
  /// Requires [hasParent] to be true; otherwise, yields nothing.
  /// This list is empty if this already is a root model
  Iterable<ModelCrud> parentModelPath() sync* {
    if (!hasParent) {
      return;
    }

    yield parentModel();
    yield* parentModel<ModelCrud>().parentModelPath();
  }

  /// Ensures a child model of type T exists at the specified id, creating it if necessary.
  ///
  /// Fetches existing model; if absent, sets the provided model. Returns the existing
  /// or newly created [T].
  /// Throws a [FirestoreException] if operations fail.
  @override
  Future<T> $ensureExists<T extends ModelCrud>(String id, T model) async {
    T? t = await $get<T>(id);
    if (t == null) {
      await $set<T>(id, model);
      return model;
    }

    return t;
  }

  /// Ensures the unique child model of type T exists, creating it if necessary.
  ///
  /// Similar to [$ensureExists] but for single-instance models (null id).
  /// Returns the existing or newly created [T].
  @override
  Future<T> ensureExistsUnique<T extends ModelCrud>(T model) async {
    T? t = await getUnique<T>();
    if (t == null) {
      await setUnique<T>(model);
      return model;
    }

    return t;
  }

  /// Recursively searches for a model of type T within this model and its children.
  ///
  /// Returns the first matching [T], or null if not found. Checks self first, then children.
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

  /// Determines the runtime type of the parent model.
  ///
  /// Uses [FireCrud.instance().modelForPath] with [parentDocumentPath] or the parent's
  /// template path if unavailable.
  Type get parentModelType => FireCrud.instance()
      .modelForPath(parentDocumentPath ?? getCrud().parentTemplatePath)
      .runtimeType;

  /// Retrieves the parent model instance of type T.
  ///
  /// Uses [FireCrud.instance().modelForPath] with [parentDocumentPath] or template path.
  /// Returns the parent [T].
  T parentModel<T extends ModelCrud>() => FireCrud.instance()
      .modelForPath(parentDocumentPath ?? getCrud().parentTemplatePath);

  /// Retrieves a child model of type T at the specified id from Firestore.
  ///
  /// Uses [ModelUtility.pull] to fetch and construct. Returns a [Future<T?>], null if not found.
  /// Throws a [FirestoreException] if fetch fails.
  @override
  Future<T?> $get<T extends ModelCrud>(String id) =>
      ModelUtility.pull<T>($models, $pathOf, id);

  /// Retrieves the unique child model of type T from Firestore.
  ///
  /// Uses null id. Returns a [Future<T?>].
  @override
  Future<T?> getUnique<T extends ModelCrud>() =>
      ModelUtility.pull<T>($models, $pathOf, null);

  /// Sets the unique child model of type T (null id) in Firestore.
  ///
  /// Persists via [ModelUtility.push]. No return value.
  /// Throws a [FirestoreException] if set fails.
  @override
  Future<void> setUnique<T extends ModelCrud>(T model) =>
      ModelUtility.push<T>($models, $pathOf, model, null);

  /// Atomically sets the unique child model of type T using a transaction function.
  ///
  /// Applies txn to existing data. No return value.
  /// Throws a [FirestoreException] if transaction fails.
  @override
  Future<void> setUniqueAtomic<T extends ModelCrud>(T Function(T? data) txn) =>
      ModelUtility.pushAtomic<T>($models, $pathOf, txn, null);

  /// Sets the raw data for this model instance in Firestore.
  ///
  /// Directly updates [documentPath] with the map from [getCrud<T>().toMap(self)].
  /// No return value. Requires [documentPath] to be set.
  /// Throws a [StateError] if [documentPath] is null, or [FirestoreException] if set fails.
  @override
  Future<void> setSelfRaw<T extends ModelCrud>(T self) {
    return FirestoreDatabase.instance
        .document(documentPath!)
        .set(getCrud<T>().toMap(self));
  }

  /// Sets a child model of type T at the specified id in Firestore.
  ///
  /// Persists via [ModelUtility.push]. No return value.
  /// Throws a [FirestoreException] if set fails.
  @override
  Future<void> $set<T extends ModelCrud>(String id, T model) =>
      ModelUtility.push<T>($models, $pathOf, model, id);

  /// Updates the raw data for this model instance in Firestore.
  ///
  /// Applies updates map to [documentPath] if non-empty. No-op if empty.
  /// No return value. Requires [documentPath] to be set.
  /// Throws a [StateError] if [documentPath] is null, or [FirestoreException] if update fails.
  @override
  Future<void> updateSelfRaw<T extends ModelCrud>(
          Map<String, dynamic> updates) =>
      updates.isEmpty
          ? Future.value()
          : FirestoreDatabase.instance.document(documentPath!).update(updates);

  /// Atomically sets a child model of type T at id using a transaction function.
  ///
  /// Applies txn to existing data. No return value.
  /// Throws a [FirestoreException] if transaction fails.
  @override
  Future<void> $setAtomic<T extends ModelCrud>(
          String id, T Function(T? data) txn) =>
      ModelUtility.pushAtomic<T>($models, $pathOf, txn, id);

  /// Atomically sets the raw data for this model using a transaction function.
  ///
  /// Updates [documentPath] via Firestore transaction. No return value.
  /// Requires [documentPath] to be set. Throws [StateError] if null, or [FirestoreException].
  @override
  Future<void> setSelfAtomicRaw<T extends ModelCrud>(T Function(T? data) txn) =>
      FirestoreDatabase.instance.document(documentPath!).setAtomic((data) =>
          getCrud<T>()
              .toMap(txn(data == null ? null : getCrud<T>().fromMap(data))));

  /// Streams real-time changes to this model instance from Firestore.
  ///
  /// Maps snapshot data to [T] using [getCrud<T>().withPath]. Emits this if no data.
  /// Returns a [Stream<T>]. Requires [documentPath] to be set.
  /// Throws a [StateError] if [documentPath] is null.
  @override
  Stream<T> streamSelfRaw<T extends ModelCrud>() => FirestoreDatabase.instance
      .document(documentPath!)
      .stream
      .map((event) => (event.data == null
          ? this
          : getCrud<T>().withPath(event.data, documentPath!)) as T);

  /// Updates a child model of type T at id with the provided updates map.
  ///
  /// Applies partial updates via [ModelUtility.update]. No return value.
  /// Throws a [FirestoreException] if update fails.
  @override
  Future<void> $update<T extends ModelCrud>(
          String id, Map<String, dynamic> updates) =>
      ModelUtility.update<T>($models, $pathOf, updates, id);

  /// Sets a child model of type T at id only if it does not already exist.
  ///
  /// Checks existence first, then sets if absent. No return value.
  /// Throws a [FirestoreException] if operations fail.
  @override
  Future<void> setIfAbsent<T extends ModelCrud>(String id, T model) =>
      $exists(id).then((v) => v ? Future.value() : $set<T>(id, model));

  /// Sets the unique child model of type T only if it does not exist.
  ///
  /// Similar to [setIfAbsent] for null id. No return value.
  @override
  Future<void> setIfAbsentUnique<T extends ModelCrud>(T model) =>
      existsUnique<T>().then((v) => v ? Future.value() : setUnique<T>(model));

  /// Updates the unique child model of type T with the provided updates map.
  ///
  /// Uses null id. No return value.
  /// Throws a [FirestoreException] if update fails.
  @override
  Future<void> updateUnique<T extends ModelCrud>(
          Map<String, dynamic> updates) =>
      ModelUtility.update<T>($models, $pathOf, updates, null);

  /// Retrieves the raw data for this model instance from Firestore.
  ///
  /// Fetches and constructs using [getCrud<T>().fromMap]. Returns [Future<T?>], null if absent.
  /// Requires [documentPath]. Throws [StateError] if null, or [FirestoreException].
  @override
  Future<T?> getSelfRaw<T extends ModelCrud>() async {
    if (documentPath == null) {
      throw Exception("Cannot get self without a document path");
    }

    return getCrud<T>().fromMap(
        (await FirestoreDatabase.instance.document(documentPath!).get()).data ??
            {})
      ..documentPath = documentPath;
  }

  /// Retrieves cached raw data for this model instance from Firestore.
  ///
  /// Similar to [getSelfRaw] but uses cached fetch. Returns [Future<T?>].
  /// Requires [documentPath]. Throws [StateError] or [FirestoreException].
  @override
  Future<T?> getCachedSelfRaw<T extends ModelCrud>() async {
    if (documentPath == null) {
      throw Exception("Cannot get self without a document path");
    }

    return getCrud<T>().fromMap((await FirestoreDatabase.instance
                .document(documentPath!)
                .get(cached: true))
            .data ??
        {})
      ..documentPath = documentPath;
  }

  /// Deletes the raw data for this model instance from Firestore.
  ///
  /// No return value. Requires [documentPath].
  /// Throws [StateError] if null, or [FirestoreException] if delete fails.
  @override
  Future<void> deleteSelfRaw<T extends ModelCrud>() {
    if (documentPath == null) {
      throw Exception("Cannot delete self without a document path");
    }
    return FirestoreDatabase.instance.document(documentPath!).delete();
  }

  /// Checks if this model has a parent in the hierarchy.
  ///
  /// Based on the length of [getCrud().templatePath] segments (>2 indicates parent).
  /// Returns a [bool].
  bool get hasParent => getCrud().templatePath.split("/").length > 2;

  /// Checks if a child model of type T exists at the specified id.
  ///
  /// Uses [$get] and checks non-null. Returns [Future<bool>], catching errors as false.
  @override
  Future<bool> $exists<T extends ModelCrud>(String id) =>
      $get<T>(id).then((value) => value != null).catchError((e) => false);

  /// Checks if the unique child model of type T exists.
  ///
  /// Uses [getUnique]. Returns [Future<bool>].
  @override
  Future<bool> existsUnique<T extends ModelCrud>() =>
      getUnique<T>().then((value) => value != null).catchError((e) => false);

  /// Retrieves a cached child model of type T at id.
  ///
  /// Uses [ModelUtility.pullCached]. Returns [Future<T?>].
  /// Throws a [FirestoreException] if fetch fails.
  @override
  Future<T?> getCached<T extends ModelCrud>(String id) =>
      ModelUtility.pullCached<T>($models, $pathOf, id);

  /// Retrieves the cached unique child model of type T.
  ///
  /// Uses null id. Returns [Future<T?>].
  @override
  Future<T?> getCachedUnique<T extends ModelCrud>() =>
      ModelUtility.pullCached<T>($models, $pathOf, null);

  /// Updates a child model of type T at id based on changes from before to after.
  ///
  /// Computes diff using [ModelUtility.getUpdates] and applies via [$update].
  /// No return value. Throws [FirestoreException] if update fails.
  @override
  Future<void> $change<T extends ModelCrud>(String id, T before, T after) {
    FireModel<T> c = ModelUtility.selectChildModel<T>($models)!;
    return $update<T>(
        id, ModelUtility.getUpdates(c.toMap(before), c.toMap(after)));
  }

  /// Updates the unique child model of type T based on before/after changes.
  ///
  /// Uses null id. No return value.
  @override
  Future<void> changeUnique<T extends ModelCrud>(T before, T after) {
    FireModel<T> c = ModelUtility.selectChildModel<T>($models)!;
    return updateUnique<T>(
        ModelUtility.getUpdates(c.toMap(before), c.toMap(after)));
  }

  /// Updates this model instance based on before/after changes using raw update.
  ///
  /// Computes diff and applies to self. No return value.
  /// Requires valid child model selection. Throws [FirestoreException].
  @override
  Future<void> changeSelfRaw<T extends ModelCrud>(T before, T after) {
    FireModel<T> c = ModelUtility.selectChildModel<T>($models)!;
    return updateSelfRaw<T>(
        ModelUtility.getUpdates(c.toMap(before), c.toMap(after)));
  }

  /// Atomically updates a child model of type T at id using an updater function.
  ///
  /// Applies updater to initial data via [ModelUtility.updateAtomic]. No return value.
  /// Throws a [FirestoreException] if transaction fails.
  @override
  Future<void> $updateAtomic<T extends ModelCrud>(
          String id, Map<String, dynamic> Function(T? initial) updater) =>
      ModelUtility.updateAtomic<T>($models, $pathOf, updater);

  /// Atomically updates the unique child model of type T using an updater.
  ///
  /// Uses null id. No return value.
  @override
  Future<void> updateUniqueAtomic<T extends ModelCrud>(
          Map<String, dynamic> Function(T? initial) updater) =>
      ModelUtility.updateAtomic<T>($models, $pathOf, updater, null);

  /// Atomically updates this model instance using a transaction updater.
  ///
  /// Applies to [documentPath] via Firestore updateAtomic. No return value.
  /// Requires [documentPath]. Throws [StateError] or [FirestoreException].
  @override
  Future<void> updateSelfAtomicRaw<T extends ModelCrud>(
          Map<String, dynamic> Function(T? initial) txn) =>
      FirestoreDatabase.instance.document(documentPath!).updateAtomic(
          (data) => txn(data == null ? null : getCrud<T>().fromMap(data)));
}
