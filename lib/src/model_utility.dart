import 'package:collection_walker/collection_walker.dart';
import 'package:fire_api/fire_api.dart';
import 'package:fire_crud/fire_crud.dart';
import 'package:toxic/extensions/iterable.dart';

/// Utility class providing helper functions for operations on [FireModel] instances within the fire_crud package.
///
/// This class offers static methods for selecting, querying, manipulating, and streaming [FireModel] objects,
/// particularly those extending [ModelCrud]. It facilitates common Firestore interactions such as pulling data,
/// updating documents, handling pagination with [ModelPage], and computing efficient updates via [getUpdates].
/// Key features include child model selection, collection viewing/walking, atomic operations, and map flattening/unflattening
/// for nested data handling. Designed for use in conjunction with [RootFireCrud] and [ModelAccessor] for streamlined
/// model management in Firestore-based applications.
class ModelUtility {
  /// Selects the first [FireModel]<T> from a list of models, where T extends [ModelCrud].
  ///
  /// If no matching model is found, prints a warning and returns null. Primarily used to identify
  /// child models by type in a collection of [FireModel] instances.
  ///
  /// @param models The list of [FireModel] instances to search.
  /// @param id Optional identifier for further filtering (unused in current implementation).
  /// @returns The selected [FireModel]<T> or null if not found.
  static FireModel<T>? selectChildModel<T extends ModelCrud>(
      List<FireModel> models,
      [String? id]) {
    FireModel<T>? c = models.whereType<FireModel<T>>().firstOrNull;

    if (c == null) {
      print("WARNING: No child model found for ChildModel<$T>.");
    }

    return c;
  }

  /// Selects a [FireModel]<T> from a list by matching the collection name, where T extends [ModelCrud].
  ///
  /// Filters models based on the [collection] property and casts to the expected type. Returns null if no match.
  /// Useful for retrieving models associated with a specific Firestore collection.
  ///
  /// @param models The list of [FireModel] instances to search.
  /// @param collection The collection name to match.
  /// @param id Optional identifier (unused in current implementation).
  /// @returns The matching [FireModel]<T> or null.
  static FireModel<T>? selectChildModelByCollection<T extends ModelCrud>(
      List<FireModel> models, String collection,
      [String? id]) {
    return models.select((e) => e.collection == collection) as FireModel<T>?;
  }

  /// Selects a [FireModel]<T> from a list by type, excluding those with an exclusive document ID, where T extends [ModelCrud].
  ///
  /// Intended for identifying collection-level models without specific document bindings. Returns null if no match.
  ///
  /// @param models The list of [FireModel] instances to search.
  /// @returns The selected collection-level [FireModel]<T> or null.
  static FireModel<T>? selectChildModelCollectionByType<T extends ModelCrud>(
      List<FireModel> models) {
    return models
        .whereType<FireModel<T>>()
        .select((e) => e.exclusiveDocumentId == null);
  }

  /// Creates a [CollectionViewer]<T> for the specified collection path using models, where T extends [ModelCrud].
  ///
  /// Selects the appropriate child model and applies an optional query transformer. Provides a view for observing
  /// Firestore collection changes without full streaming overhead.
  ///
  /// @param collectionPath The base path for the Firestore collection.
  /// @param models The list of [FireModel] instances to derive the viewer from.
  /// @param query Optional function to transform the [CollectionReference].
  /// @returns A configured [CollectionViewer]<T> instance.
  static CollectionViewer<T> view<T extends ModelCrud>(
      String collectionPath, List<FireModel> models,
      [CollectionReference Function(CollectionReference ref)? query]) {
    FireModel<T> c = selectChildModelCollectionByType<T>(models)!;
    return CollectionViewer<T>(
      crud: c.cloneWithPath("$collectionPath/*"),
      query: query,
    );
  }

  /// Creates a [CollectionWalker]<T> for paginated traversal of the specified collection, where T extends [ModelCrud].
  ///
  /// Selects the child model and sets up a walker with document conversion using the model's [withPath] method.
  /// Supports optional query transformation for custom filtering or ordering.
  ///
  /// @param collectionPath The base path for the Firestore collection.
  /// @param models The list of [FireModel] instances to derive the walker from.
  /// @param query Optional function to transform the [CollectionReference].
  /// @returns A configured [CollectionWalker]<T> instance for iteration.
  static CollectionWalker<T> walk<T extends ModelCrud>(
      String collectionPath, List<FireModel> models,
      [CollectionReference Function(CollectionReference ref)? query]) {
    FireModel<T> c = selectChildModelCollectionByType<T>(models)!;
    return CollectionWalker<T>(
      query:
          (query?.call(FirestoreDatabase.instance.collection(collectionPath)) ??
              FirestoreDatabase.instance.collection(collectionPath)),
      documentConverter: (doc) async => c.withPath(doc.data ?? {}, doc.path)!,
    );
  }

  /// Deletes all documents in the specified collection asynchronously, where T extends [ModelCrud].
  ///
  /// Selects the child model and applies an optional query to fetch documents, then deletes each using [deleteSelfRaw].
  /// No return value; throws if Firestore operations fail.
  ///
  /// @param collectionPath The path of the Firestore collection to clear.
  /// @param models The list of [FireModel] instances to derive the deleter from.
  /// @param query Optional function to transform the [CollectionReference] for targeted deletion.
  static Future<void> deleteAll<T extends ModelCrud>(
      String collectionPath, List<FireModel> models,
      [CollectionReference Function(CollectionReference ref)? query]) {
    FireModel<T> c = selectChildModelCollectionByType<T>(models)!;
    return (query
                ?.call(FirestoreDatabase.instance.collection(collectionPath)) ??
            FirestoreDatabase.instance.collection(collectionPath))
        .get()
        .then((value) => Future.wait(value.map(
            (e) => c.withPath(e.data, e.reference.path)!.deleteSelfRaw())));
  }

  /// Retrieves all documents from the specified collection as a list of T, where T extends [ModelCrud].
  ///
  /// Selects the child model, applies optional query, and converts fetched documents using [withPath].
  ///
  /// @param collectionPath The path of the Firestore collection.
  /// @param models The list of [FireModel] instances to derive the puller from.
  /// @param query Optional function to transform the [CollectionReference].
  /// @returns A [Future] completing with the list of T instances.
  static Future<List<T>> pullAll<T extends ModelCrud>(
      String collectionPath, List<FireModel> models,
      [CollectionReference Function(CollectionReference ref)? query]) {
    FireModel<T> c = selectChildModelCollectionByType<T>(models)!;
    return (query
                ?.call(FirestoreDatabase.instance.collection(collectionPath)) ??
            FirestoreDatabase.instance.collection(collectionPath))
        .get()
        .then((value) =>
            value.map((e) => c.withPath(e.data, e.reference.path)!).toList());
  }

  /// Pulls a paginated [ModelPage]<T> from the collection, supporting forward/backward navigation, where T extends [ModelCrud].
  ///
  /// Uses the provided previous page for cursor-based pagination. Returns null if no more items or page is exhausted.
  /// Integrates with Firestore's [getDocumentPageInCollection] for efficient querying.
  ///
  /// @param collectionPath The path of the Firestore collection.
  /// @param models The list of [FireModel] instances.
  /// @param query Optional query transformer.
  /// @param previousPage The prior [ModelPage] for pagination state.
  /// @param pageSize Number of items per page (default 50).
  /// @param reversed If true, paginates in reverse order.
  /// @returns A [Future] with the next [ModelPage]<T> or null.
  static Future<ModelPage<T>?> pullPage<T extends ModelCrud>({
    required String collectionPath,
    required List<FireModel> models,
    CollectionReference Function(CollectionReference ref)? query,
    ModelPage<T>? previousPage,
    int pageSize = 50,
    bool reversed = false,
  }) async {
    FireModel<T> c = selectChildModelCollectionByType<T>(models)!;
    CollectionReference ref =
        (query?.call(FirestoreDatabase.instance.collection(collectionPath)) ??
            FirestoreDatabase.instance.collection(collectionPath));

    if (previousPage != null && previousPage.items.length < pageSize) {
      return null;
    }

    DocumentPage? page = await FirestoreDatabase.instance
        .getDocumentPageInCollection(
            reference: ref,
            pageSize: pageSize,
            reversed: reversed,
            previousPage: previousPage?._page);

    if (page == null || page.documents.isEmpty) {
      return null;
    }

    return ModelPage<T>(
        page,
        page.documents
            .map((e) => c.withPath(e.data, e.reference.path)!)
            .toList(),
        collectionPath,
        models,
        pageSize,
        query,
        reversed);
  }

  /// Streams all documents from the specified collection as a list of T, where T extends [ModelCrud].
  ///
  /// Selects the child model and maps Firestore snapshot events to lists of T using [withPath], filtering non-null results.
  /// Provides real-time updates for the entire collection.
  ///
  /// @param collectionPath The path of the Firestore collection.
  /// @param models The list of [FireModel] instances.
  /// @param query Optional query transformer.
  /// @returns A [Stream] of [List]<T> reflecting collection changes.
  static Stream<List<T>> streamAll<T extends ModelCrud>(
      String collectionPath, List<FireModel> models,
      [CollectionReference Function(CollectionReference ref)? query]) {
    FireModel<T> c = selectChildModelCollectionByType<T>(models)!;
    return (query
                ?.call(FirestoreDatabase.instance.collection(collectionPath)) ??
            FirestoreDatabase.instance.collection(collectionPath))
        .stream
        .map((event) => event
            .map((e) => c.withPath(e.data, e.reference.path))
            .whereType<T>()
            .toList());
  }

  /// Counts the number of documents in the specified collection asynchronously, where T extends [ModelCrud].
  ///
  /// Applies optional query and uses Firestore's built-in count operation.
  ///
  /// @param collectionPath The path of the Firestore collection.
  /// @param models The list of [FireModel] instances (used for type selection).
  /// @param query Optional query transformer.
  /// @returns A [Future] with the document count as an integer.
  static Future<int> count<T extends ModelCrud>(
      String collectionPath, List<FireModel> models,
      [CollectionReference Function(CollectionReference ref)? query]) {
    return (query
                ?.call(FirestoreDatabase.instance.collection(collectionPath)) ??
            FirestoreDatabase.instance.collection(collectionPath))
        .count();
  }

  /// Creates a new instance of T by cloning a selected [FireModel]<T> with a custom path, where T extends [ModelCrud].
  ///
  /// Uses [selectChildModel] to find the base model and applies the path via [pathOf].
  ///
  /// @param models The list of [FireModel] instances.
  /// @param pathOf Function to generate the document path from the model and optional ID.
  /// @param id Optional identifier for path generation.
  /// @returns A new T instance with the specified path.
  static T model<T extends ModelCrud>(
      List<FireModel> models, String Function(FireModel c, [String? id]) pathOf,
      [String? id]) {
    FireModel<T> c = selectChildModel<T>(models, id)!;
    return c.cloneWithPath(pathOf(c, id));
  }

  /// Creates a new instance of T by cloning a selected [FireModel]<T> within a specific collection, where T extends [ModelCrud].
  ///
  /// Similar to [model] but selects by collection name using [selectChildModelByCollection].
  ///
  /// @param models The list of [FireModel] instances.
  /// @param pathOf Function to generate the document path.
  /// @param collection The collection name to match.
  /// @param id Optional identifier.
  /// @returns A new T instance bound to the collection.
  static T modelInCollection<T extends ModelCrud>(List<FireModel> models,
      String Function(FireModel c, [String? id]) pathOf, String collection,
      [String? id]) {
    FireModel<T> c = selectChildModelByCollection<T>(models, collection, id)!;
    return c.cloneWithPath(pathOf(c, id));
  }

  /// Pulls a single document as T asynchronously from Firestore, where T extends [ModelCrud].
  ///
  /// Selects the child model, fetches the document using [pathOf], and constructs T via [withPath].
  /// Returns null if the document does not exist.
  ///
  /// @param models The list of [FireModel] instances.
  /// @param pathOf Function to generate the document path.
  /// @param id Optional identifier.
  /// @returns A [Future] with the T instance or null.
  static Future<T?> pull<T extends ModelCrud>(
      List<FireModel> models, String Function(FireModel c, [String? id]) pathOf,
      [String? id]) async {
    FireModel<T> c = selectChildModel<T>(models, id)!;
    DocumentReference ref = FirestoreDatabase.instance.document(pathOf(c, id));
    return c.withPath((await ref.get()).data, ref.path);
  }

  /// Pulls a single document as T asynchronously with caching enabled, where T extends [ModelCrud].
  ///
  /// Identical to [pull] but uses cached reads via `get(cached: true)` for performance in repeated queries.
  ///
  /// @param models The list of [FireModel] instances.
  /// @param pathOf Function to generate the document path.
  /// @param id Optional identifier.
  /// @returns A [Future] with the T instance or null.
  static Future<T?> pullCached<T extends ModelCrud>(
      List<FireModel> models, String Function(FireModel c, [String? id]) pathOf,
      [String? id]) async {
    FireModel<T> c = selectChildModel<T>(models, id)!;
    DocumentReference ref = FirestoreDatabase.instance.document(pathOf(c, id));
    return c.withPath((await ref.get(cached: true)).data, ref.path);
  }

  /// Pushes a T instance to Firestore by setting the document data, where T extends [ModelCrud].
  ///
  /// Selects the child model and uses [toMap] to serialize the model for the path generated by [pathOf].
  /// Overwrites the document if it exists.
  ///
  /// @param models The list of [FireModel] instances.
  /// @param pathOf Function to generate the document path.
  /// @param model The T instance to push.
  /// @param id Optional identifier.
  static Future<void> push<T extends ModelCrud>(List<FireModel> models,
      String Function(FireModel c, [String? id]) pathOf, T model,
      [String? id]) async {
    FireModel<T> c = selectChildModel<T>(models)!;
    await FirestoreDatabase.instance
        .document(pathOf(c, id))
        .set(c.toMap(model));
  }

  /// Updates a document in Firestore with partial data for T, where T extends [ModelCrud].
  ///
  /// Selects the child model and applies the [data] map to the path via [update]. Fails if document does not exist.
  ///
  /// @param models The list of [FireModel] instances.
  /// @param pathOf Function to generate the document path.
  /// @param data The partial updates as a [Map].
  /// @param id Optional identifier.
  static Future<void> update<T extends ModelCrud>(
      List<FireModel> models,
      String Function(FireModel c, [String? id]) pathOf,
      Map<String, dynamic> data,
      [String? id]) async {
    FireModel<T> c = selectChildModel<T>(models)!;
    await FirestoreDatabase.instance.document(pathOf(c, id)).update(data);
  }

  /// Performs an atomic update on a document for T using a transformation function, where T extends [ModelCrud].
  ///
  /// Selects the child model and applies [data] (derived from initial document state) via [updateAtomic].
  /// Ensures consistency in concurrent scenarios by basing updates on the current document value.
  ///
  /// @param models The list of [FireModel] instances.
  /// @param pathOf Function to generate the document path.
  /// @param data Function that receives the initial T? and returns update map.
  /// @param id Optional identifier.
  static Future<void> updateAtomic<T extends ModelCrud>(
      List<FireModel> models,
      String Function(FireModel c, [String? id]) pathOf,
      Map<String, dynamic> Function(T? initial) data,
      [String? id]) async {
    FireModel<T> c = selectChildModel<T>(models)!;
    await FirestoreDatabase.instance
        .document(pathOf(c, id))
        .updateAtomic((init) => data(init == null ? null : c.fromMap(init)));
  }

  /// Adds a new document to the collection and returns the created T instance, where T extends [ModelCrud].
  ///
  /// Selects the collection-level model, adds via Firestore [add], and clones with the generated ID and path.
  ///
  /// @param collectionPath The collection to add to.
  /// @param models The list of [FireModel] instances.
  /// @param pathOf Function to generate the full path post-add.
  /// @param model The T instance to add.
  /// @returns A [Future] with the added T including its new ID.
  static Future<T> add<T extends ModelCrud>(
      String collectionPath,
      List<FireModel> models,
      String Function(FireModel c, [String? id]) pathOf,
      T model) async {
    FireModel<T> c = selectChildModelCollectionByType<T>(models)!;
    DocumentReference r = await FirestoreDatabase.instance
        .collection(collectionPath)
        .add(c.toMap(model));
    return c.cloneWithPath(pathOf(c, r.id), model);
  }

  /// Deletes a document from Firestore for T, where T extends [ModelCrud].
  ///
  /// Selects the child model and deletes the document at the path generated by [pathOf].
  ///
  /// @param models The list of [FireModel] instances.
  /// @param pathOf Function to generate the document path.
  /// @param id Optional identifier.
  static Future<void> delete<T extends ModelCrud>(
      List<FireModel> models, String Function(FireModel c, [String? id]) pathOf,
      [String? id]) async {
    FireModel<T> c = selectChildModel<T>(models)!;
    await FirestoreDatabase.instance.document(pathOf(c, id)).delete();
  }

  /// Performs an atomic set operation on a document for T using a transformation, where T extends [ModelCrud].
  ///
  /// Selects the child model and applies [txn] to the current data via [setAtomic], serializing the result with [toMap].
  /// Useful for optimistic updates or conditional sets.
  ///
  /// @param models The list of [FireModel] instances.
  /// @param pathOf Function to generate the document path.
  /// @param txn Function that receives current T? and returns updated T.
  /// @param id Optional identifier.
  static Future<void> pushAtomic<T extends ModelCrud>(
      List<FireModel> models,
      String Function(FireModel c, [String? id]) pathOf,
      T Function(T? data) txn,
      [String? id]) async {
    FireModel<T> c = selectChildModel<T>(models)!;
    await FirestoreDatabase.instance.document(pathOf(c, id)).setAtomic(
        (data) => c.toMap(txn(data == null ? null : c.fromMap(data))));
  }

  /// Streams a single document as T from Firestore, where T extends [ModelCrud].
  ///
  /// Selects the child model and maps snapshot events to T using [withPath]. Emits null if document is missing.
  ///
  /// @param models The list of [FireModel] instances.
  /// @param pathOf Function to generate the document path.
  /// @param id Optional identifier.
  /// @returns A [Stream] of T? reflecting document changes.
  static Stream<T?> stream<T extends ModelCrud>(
      List<FireModel> models, String Function(FireModel c, [String? id]) pathOf,
      [String? id]) {
    FireModel<T> c = selectChildModel<T>(models, id)!;

    return FirestoreDatabase.instance
        .document(pathOf(c, id))
        .stream
        .map((event) => c.withPath(event.data, event.reference.path));
  }

  /// Computes the minimal update map for Firestore by diffing two maps (before and after states).
  ///
  /// Flattens nested structures, detects changes, deletions, increments for numerics, and array unions/removals for simple lists.
  /// Returns a map suitable for [update] or [set] operations, using [FieldValue] for special operations like delete or increment.
  /// Handles nested maps by flattening paths (e.g., 'a.b' for {a: {b: value}}).
  ///
  /// @param before The original map state.
  /// @param after The new map state.
  /// @returns A [Map] of changes, including [FieldValue] instances for optimized updates.
  static Map<String, dynamic> getUpdates(
      Map<String, dynamic> before, Map<String, dynamic> after) {
    Map<String, dynamic> changes = <String, dynamic>{};
    Map<String, dynamic> flatBefore = _flatten(before);
    Map<String, dynamic> flatAfter = _flatten(after);

    Set<String> paths = <String>{};
    paths.addAll(flatBefore.keys);
    paths.addAll(flatAfter.keys);

    for (String path in paths) {
      dynamic a = flatBefore[path];
      dynamic b = flatAfter[path];

      if (a == b) {
        continue;
      }

      if (b == null) {
        changes[path] = FieldValue.delete();
        continue;
      }

      if (a == null) {
        changes[path] = b;
        continue;
      }

      if (a is int && b is int) {
        changes[path] = FieldValue.increment(b - a);
        continue;
      }

      if (a is double && b is double) {
        changes[path] = FieldValue.increment(b - a);
        continue;
      }

      if (a is List && b is List) {
        changes[path] = _diffLists(a, b) ?? b;
        continue;
      }

      changes[path] = b;
    }

    return changes;
  }

  /// Internal helper to compute Firestore array diff for simple lists.
  ///
  /// Detects additions or removals in uniform-type lists (primitives only, no nested structures).
  /// Returns [FieldValue.arrayUnion] for adds, [FieldValue.arrayRemove] for removes, or null if complex/replace needed.
  ///
  /// @param a The original list.
  /// @param b The new list.
  /// @returns [FieldValue] for union/remove or null.
  static dynamic _diffLists(List<dynamic> a, List<dynamic> b) {
    if (!_isSimpleList(a) || !_isSimpleList(b)) {
      return null;
    }

    List<dynamic> toAdd = b.where((dynamic e) => !a.contains(e)).toList();
    List<dynamic> toRemove = a.where((dynamic e) => !b.contains(e)).toList();

    if ((toAdd.isEmpty && toRemove.isEmpty) ||
        (toAdd.isNotEmpty && toRemove.isNotEmpty)) {
      return null;
    }

    return toAdd.isNotEmpty
        ? FieldValue.arrayUnion(toAdd)
        : FieldValue.arrayRemove(toRemove);
  }

  /// Internal helper to check if a list contains only simple, uniform primitive elements.
  ///
  /// Validates no nested maps/lists and consistent runtime types across elements.
  ///
  /// @param list The list to inspect.
  /// @returns True if simple and uniform, false otherwise.
  static bool _isSimpleList(List<dynamic> list) {
    Type? baseType;

    for (dynamic element in list) {
      if (element is Map || element is List) {
        return false;
      }

      baseType ??= element.runtimeType;

      if (baseType != element.runtimeType) {
        return false;
      }
    }
    return true;
  }

  /// Internal recursive helper to flatten a nested map into dot-notated paths.
  ///
  /// Converts {a: {b: 1}} to {'a.b': 1}. Preserves values at leaf nodes.
  ///
  /// @param map The nested map to flatten.
  /// @param prefix Current path prefix (default empty).
  /// @returns A flat [Map] with dotted keys.
  static Map<String, dynamic> _flatten(Map<String, dynamic> map,
      {String prefix = ''}) {
    Map<String, dynamic> out = <String, dynamic>{};
    map.forEach((String key, dynamic value) {
      String fullKey = prefix.isEmpty ? key : '$prefix$key';
      if (value is Map<String, dynamic>) {
        out.addAll(_flatten(value, prefix: '$fullKey.'));
      } else {
        out[fullKey] = value;
      }
    });
    return out;
  }

  /// Internal helper to reconstruct a nested map from a flat dot-notated map.
  ///
  /// Reverses [_flatten], building nested structures from paths like 'a.b' back to {a: {b: value}}.
  ///
  /// @param flat The flat map with dotted keys.
  /// @returns The reconstructed nested [Map].
  static Map<String, dynamic> unflatten(Map<String, dynamic> flat) {
    Map<String, dynamic> root = <String, dynamic>{};
    flat.forEach((String path, dynamic value) {
      List<String> parts = path.split('.');
      Map<String, dynamic> cursor = root;
      for (int i = 0; i < parts.length; i++) {
        String part = parts[i];
        if (i == parts.length - 1) {
          cursor[part] = value;
        } else {
          if (cursor[part] == null || cursor[part] is! Map<String, dynamic>) {
            cursor[part] = <String, dynamic>{};
          }
          cursor = cursor[part] as Map<String, dynamic>;
        }
      }
    });
    return root;
  }
}

/// Represents a paginated page of [ModelCrud] instances from a Firestore collection.
///
/// Wraps a [DocumentPage] with converted model items (T), pagination metadata, and utilities for
/// fetching subsequent pages via [nextPage]. Used in conjunction with [ModelUtility.pullPage] for
/// efficient cursor-based pagination in fire_crud applications. Supports query customization and
/// reverse ordering for flexible data retrieval.
class ModelPage<T extends ModelCrud> {
  /// The underlying [DocumentPage] from Firestore, containing raw document references and cursors.
  final DocumentPage _page;

  /// The list of converted T model instances for this page.
  final List<T> items;

  /// The Firestore collection path this page was pulled from.
  final String collectionPath;

  /// The list of [FireModel] instances used to derive the models in [items].
  final List<FireModel> models;

  /// The requested size of each page (may return fewer if end of data).
  final int pageSize;

  /// Optional query transformer function for subsequent pages.
  final CollectionReference Function(CollectionReference ref)? query;

  /// Flag indicating if pagination should proceed in reverse order.
  final bool reversed;

  /// Constructs a [ModelPage] from the raw [DocumentPage], converted items, and pagination details.
  ///
  /// Initializes all fields directly. No special behavior; ensures items are properly typed as T
  /// extending [ModelCrud] for use with fire_crud utilities.
  ///
  /// @param _page The raw Firestore [DocumentPage].
  /// @param items The list of T models.
  /// @param collectionPath The source collection.
  /// @param models The [FireModel] list.
  /// @param pageSize The page size.
  /// @param query The query function.
  /// @param reversed The reverse flag.
  ModelPage(this._page, this.items, this.collectionPath, this.models,
      this.pageSize, this.query, this.reversed);

  /// Fetches the next page asynchronously if more items are available.
  ///
  /// Checks if current [items] length is less than [pageSize]; if so, returns null (end of data).
  /// Otherwise, delegates to [ModelUtility.pullPage] with current state for continuation.
  ///
  /// @returns A [Future] with the next [ModelPage]<T> or null if no more pages.
  Future<ModelPage<T>?> nextPage() => items.length < pageSize
      ? Future.value(null)
      : ModelUtility.pullPage<T>(
          collectionPath: collectionPath,
          models: models,
          previousPage: this,
          pageSize: pageSize,
          query: query,
          reversed: reversed);
}
