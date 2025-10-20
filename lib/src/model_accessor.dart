import 'package:collection_walker/collection_walker.dart';
import 'package:fire_api/fire_api.dart';
import 'package:fire_crud/fire_crud.dart';

/// Abstract interface for accessing and manipulating child models within a Firestore document hierarchy in the fire_crud package.
///
/// This class enables dynamic CRUD operations (create, read, update, delete), streaming, pagination, and querying on subcollections
/// based on [ModelCrud] types. It supports child model resolution by type, unique instances, and raw self-referential access.
/// Key features include atomic updates, existence checks, and integration with [CollectionWalker] and [CollectionViewer] for
/// collection traversal and viewing. Implementations typically wrap a Firestore document reference to provide model-specific access.
abstract class ModelAccessor {
  /// Getter for the list of [FireModel] instances associated with this accessor, typically representing the models
  /// managed or referenced by the underlying document.
  List<FireModel> get $models;

  /// Constructs the Firestore path for the given [FireModel] instance, optionally appending an ID for document-specific paths.
  String $pathOf(FireModel c, [String? id]);

  /// Creates a [CollectionWalker] for the given model type which should be a child collection of THIS document.
  ///
  /// The [query] callback allows customizing the [CollectionReference] for the subcollection. Returns a walker for
  /// traversing and operating on the collection of type T, where T extends [ModelCrud].
  CollectionWalker<T> walk<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  /// Creates a [CollectionViewer] for the given model type which should be a child collection of THIS document.
  ///
  /// The [query] callback allows customizing the [CollectionReference] for the subcollection. Returns a viewer for
  /// observing and querying the collection of type T, where T extends [ModelCrud].
  CollectionViewer<T> view<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  /// Gets a child model type in a subcollection of this document. The type determines what the subcollection actually is.
  ///
  /// Optionally specifies an [id] to retrieve a specific document. Returns an instance of T, where T extends [ModelCrud],
  /// or null if not found.
  T $model<T extends ModelCrud>([String? id]);

  /// Retrieves the unique instance of the model type T in the subcollection, assuming a single document exists.
  ///
  /// Returns the instance of T, where T extends [ModelCrud]. Throws if multiple or no instances found.
  T modelUnique<T extends ModelCrud>();

  /// Retrieves a model of type T from the specified [collection] subcollection, optionally by [id].
  ///
  /// Returns an instance of T, where T extends [ModelCrud], or null if not found.
  T modelInCollection<T extends ModelCrud>(String collection, [String? id]);

  /// Checks if a document with the given [id] exists in the subcollection for type T.
  ///
  /// Returns true if the document exists, false otherwise. T extends [ModelCrud].
  Future<bool> $exists<T extends ModelCrud>(String id);

  /// Checks if a unique document exists for the model type T in the subcollection.
  ///
  /// Returns true if exactly one document exists, false otherwise. T extends [ModelCrud].
  Future<bool> existsUnique<T extends ModelCrud>();

  /// Retrieves the document with the given [id] from the subcollection for type T.
  ///
  /// Returns the instance of T if found, null otherwise. T extends [ModelCrud].
  Future<T?> $get<T extends ModelCrud>(String id);

  /// Retrieves the unique instance of the model type T from the subcollection.
  ///
  /// Returns the instance of T if found, null otherwise. Throws if multiple instances exist. T extends [ModelCrud].
  Future<T?> getUnique<T extends ModelCrud>();

  /// Retrieves the document with the given [id] from the subcollection for type T, using cache if available.
  ///
  /// Returns the instance of T if found, null otherwise. T extends [ModelCrud].
  Future<T?> getCached<T extends ModelCrud>(String id);

  /// Retrieves the unique cached instance of the model type T from the subcollection.
  ///
  /// Returns the instance of T if found, null otherwise. Throws if multiple instances exist. T extends [ModelCrud].
  Future<T?> getCachedUnique<T extends ModelCrud>();

  /// Retrieves the raw self-referential model of type T without type-specific processing.
  ///
  /// Returns the instance of T if found, null otherwise. T extends [ModelCrud].
  Future<T?> getSelfRaw<T extends ModelCrud>();

  /// Retrieves the cached raw self-referential model of type T without type-specific processing.
  ///
  /// Returns the instance of T if found, null otherwise. T extends [ModelCrud].
  Future<T?> getCachedSelfRaw<T extends ModelCrud>();

  /// Finds a model of type T among the associated models without Firestore access.
  ///
  /// Returns the first matching instance of T, or null if none found. T extends [ModelCrud].
  T? findModel<T extends ModelCrud>();

  /// Ensures a document with the given [id] exists for type T, creating or updating with the provided [model] if necessary.
  ///
  /// Returns the ensured instance of T. T extends [ModelCrud].
  Future<T> $ensureExists<T extends ModelCrud>(String id, T model);

  /// Ensures a unique document exists for type T, creating or updating with the provided [model] if necessary.
  ///
  /// Returns the ensured instance of T. Throws if multiple instances would result. T extends [ModelCrud].
  Future<T> ensureExistsUnique<T extends ModelCrud>(T model);

  /// Sets the document with the given [id] for type T only if it does not already exist, using the provided [model].
  ///
  /// No return value; performs the set operation atomically. T extends [ModelCrud].
  Future<void> setIfAbsent<T extends ModelCrud>(String id, T model);

  /// Sets the unique document for type T only if it does not already exist, using the provided [model].
  ///
  /// No return value; performs the set operation atomically. Throws if multiple instances exist. T extends [ModelCrud].
  Future<void> setIfAbsentUnique<T extends ModelCrud>(T model);

  /// Sets the raw self-referential model of type T with the provided [self] instance.
  ///
  /// No return value; updates the document directly. T extends [ModelCrud].
  Future<void> setSelfRaw<T extends ModelCrud>(T self);

  /// Atomically sets the raw self-referential model of type T using a transaction function [txn] applied to existing data.
  ///
  /// The [txn] function receives the current data and returns the updated instance. No return value. T extends [ModelCrud].
  Future<void> setSelfAtomicRaw<T extends ModelCrud>(T Function(T? data) txn);

  /// Sets the document with the given [id] for type T using the provided [model].
  ///
  /// No return value; overwrites the document. T extends [ModelCrud].
  Future<void> $set<T extends ModelCrud>(String id, T model);

  /// Streams changes to the raw self-referential model of type T.
  ///
  /// Returns a stream of T instances reflecting real-time updates. T extends [ModelCrud].
  Stream<T> streamSelfRaw<T extends ModelCrud>();

  /// Updates the document with the given [id] for type T using the provided [updates] map.
  ///
  /// No return value; applies partial updates. T extends [ModelCrud].
  Future<void> $update<T extends ModelCrud>(
      String id, Map<String, dynamic> updates);

  /// Updates the unique document for type T using the provided [updates] map.
  ///
  /// No return value; applies partial updates. Throws if multiple instances exist. T extends [ModelCrud].
  Future<void> updateUnique<T extends ModelCrud>(Map<String, dynamic> updates);

  /// Updates the raw self-referential model of type T using the provided [updates] map.
  ///
  /// No return value; applies partial updates. T extends [ModelCrud].
  Future<void> updateSelfRaw<T extends ModelCrud>(Map<String, dynamic> updates);

  /// Deletes the raw self-referential model of type T.
  ///
  /// No return value; removes the document. T extends [ModelCrud].
  Future<void> deleteSelfRaw<T extends ModelCrud>();

  /// Atomically sets the document with the given [id] for type T using a transaction function [txn] applied to existing data.
  ///
  /// The [txn] function receives the current data and returns the updated instance. No return value. T extends [ModelCrud].
  Future<void> $setAtomic<T extends ModelCrud>(
      String id, T Function(T? data) txn);

  /// Sets the unique document for type T using the provided [model].
  ///
  /// No return value; overwrites the document. Throws if multiple instances exist. T extends [ModelCrud].
  Future<void> setUnique<T extends ModelCrud>(T model);

  /// Atomically sets the unique document for type T using a transaction function [txn] applied to existing data.
  ///
  /// The [txn] function receives the current data and returns the updated instance. No return value. T extends [ModelCrud].
  Future<void> setUniqueAtomic<T extends ModelCrud>(T Function(T? data) txn);

  /// Deletes the document with the given [id] for type T.
  ///
  /// No return value; removes the document. T extends [ModelCrud].
  Future<void> $delete<T extends ModelCrud>(String id);

  /// Deletes the unique document for type T.
  ///
  /// No return value; removes the document. Throws if multiple instances exist. T extends [ModelCrud].
  Future<void> deleteUnique<T extends ModelCrud>();

  /// Streams changes to the document with the given [id] for type T.
  ///
  /// Returns a stream of T? instances (nullable for deletion events) reflecting real-time updates. T extends [ModelCrud].
  Stream<T?> $stream<T extends ModelCrud>(String id);

  /// Streams changes to the unique document for type T.
  ///
  /// Returns a stream of T? instances (nullable for deletion events) reflecting real-time updates. T extends [ModelCrud].
  Stream<T?> streamUnique<T extends ModelCrud>();

  /// Adds a new document for type T using the provided [model], generating an ID.
  ///
  /// Returns the added instance of T with its generated ID. T extends [ModelCrud].
  Future<T> $add<T extends ModelCrud>(T model);

  /// Retrieves all documents in the subcollection for type T, optionally filtered by [query].
  ///
  /// Returns a list of T instances. T extends [ModelCrud].
  Future<List<T>> getAll<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  /// Paginates the subcollection for type T with the specified [pageSize], [reversed] order, and optional [query].
  ///
  /// Returns a [ModelPage]<T> for the first page, or null if empty. Subsequent pages via pagination methods. T extends [ModelCrud].
  Future<ModelPage<T>?> paginate<T extends ModelCrud>({
    int pageSize = 50,
    bool reversed = false,
    CollectionReference Function(CollectionReference ref)? query,
  });

  /// Deletes all documents in the subcollection for type T, optionally filtered by [query].
  ///
  /// No return value; batch deletes all matching documents. T extends [ModelCrud].
  Future<void> deleteAll<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  /// Streams all documents in the subcollection for type T, optionally filtered by [query].
  ///
  /// Returns a stream of List<T> reflecting real-time changes. T extends [ModelCrud].
  Stream<List<T>> streamAll<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  /// Counts the number of documents in the subcollection for type T, optionally filtered by [query].
  ///
  /// Returns the count as an integer. T extends [ModelCrud].
  Future<int> $count<T extends ModelCrud>(
      [CollectionReference Function(CollectionReference ref)? query]);

  /// Notifies of a change from [before] to [after] state for the document with [id] of type T, typically for logging or hooks.
  ///
  /// No return value; handles change notification. T extends [ModelCrud].
  Future<void> $change<T extends ModelCrud>(String id, T before, T after);

  /// Notifies of a change from [before] to [after] state for the unique document of type T.
  ///
  /// No return value; handles change notification. Throws if multiple instances exist. T extends [ModelCrud].
  Future<void> changeUnique<T extends ModelCrud>(T before, T after);

  /// Notifies of a change from [before] to [after] state for the raw self-referential model of type T.
  ///
  /// No return value; handles change notification. T extends [ModelCrud].
  Future<void> changeSelfRaw<T extends ModelCrud>(T before, T after);

  /// Atomically updates the document with the given [id] for type T using an [updater] function applied to initial data.
  ///
  /// The [updater] receives the initial T? and returns a Map<String, dynamic> of updates. No return value. T extends [ModelCrud].
  Future<void> $updateAtomic<T extends ModelCrud>(
      String id, Map<String, dynamic> Function(T? initial) updater);

  /// Atomically updates the unique document for type T using an [updater] function applied to initial data.
  ///
  /// The [updater] receives the initial T? and returns a Map<String, dynamic> of updates. No return value. T extends [ModelCrud].
  Future<void> updateUniqueAtomic<T extends ModelCrud>(
      Map<String, dynamic> Function(T? initial) updater);

  /// Atomically updates the raw self-referential model of type T using an [updater] function applied to initial data.
  ///
  /// The [updater] receives the initial T? and returns a Map<String, dynamic> of updates. No return value. T extends [ModelCrud].
  Future<void> updateSelfAtomicRaw<T extends ModelCrud>(
      Map<String, dynamic> Function(T? initial) updater);
}
