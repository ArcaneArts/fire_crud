import 'dart:async';
import 'dart:math';

import 'package:fire_api/fire_api.dart';
import 'package:fire_crud/fire_crud.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';
import 'package:throttled/throttled.dart';
import 'package:toxic/toxic.dart';

/// Function type for building a query on a [CollectionReference].
typedef QueryBuilder = CollectionReference Function(
  CollectionReference collection,
);

/// Type alias for [DocumentSnapshot].
typedef DocSnap = DocumentSnapshot;

/// Type alias for [DocumentReference].
typedef DocRef = DocumentReference;

/// Type alias for [CollectionReference].
typedef _Q = CollectionReference;

/// Type alias for [Stream<List<DocumentSnapshot>>].
typedef _QStream = Stream<List<DocumentSnapshot>>;

/// Type alias for [StreamSubscription<List<DocumentSnapshot>>].
typedef _QSub = StreamSubscription<List<DocumentSnapshot>>;

/// Debug flag for enabling verbose logging in [CollectionViewer].
bool kCollectionViewerDebug = false;

/// Manages a view over a Firestore collection for [ModelCrud] instances, providing indexed access, streaming updates, and efficient pagination.
///
/// This class abstracts Firestore's pagination complexities, allowing users to interact with collection data via simple index-based operations.
/// It supports real-time streaming of data windows, caching for performance, and automatic size tracking. Key features include smart pulling of data around requested indices, windowed streaming with padding for smooth navigation, and cleanup to manage memory usage.
/// Used in the fire_crud package to enable efficient querying and viewing of model collections without manual handling of cursors or snapshots.
class CollectionViewer<T extends ModelCrud> {
  /// The [ModelCrud] instance providing CRUD operations for the models in this view.
  final T crud;

  /// Optional query builder function to apply custom queries to the underlying collection.
  final QueryBuilder? query;

  /// Size of the streaming window in number of documents.
  final int streamWindow;

  /// Padding around the current view index for proactive streaming.
  final int streamWindowPadding;

  /// Maximum number of snapshots to keep in memory for caching.
  final int memorySize;

  /// Cache of document snapshots mapped by their index in the collection.
  final Map<int, DocSnap> _indexCache = {};

  /// Cooldown duration before retargeting the stream window after updates.
  final Duration streamRetargetCooldown;

  /// Interval for periodically checking if the collection size has changed.
  final Duration sizeCheckInterval;

  /// Threshold for when to perform double-checks on collection size using count queries.
  final int limitedSizeDoubleCheckCountThreshold;

  /// Behavior subject emitting updates to this [CollectionViewer] instance for reactive consumption.
  final BehaviorSubject<CollectionViewer<T>> stream = BehaviorSubject();

  /// Lock for synchronizing concurrent access to cache and streaming operations.
  final Lock lock = Lock();

  /// Subscription to monitor if the collection becomes non-empty from an empty state.
  StreamSubscription<bool>? _emptyListener;

  /// Last accessed or targeted index in the collection.
  int _lastIndex = 0;

  /// Cached size of the collection; null if not yet determined or invalidated.
  int? _cacheSize;

  /// Current active stream for the data window.
  _QStream? _windowStream;

  /// Subscription to the current window stream.
  _QSub? _windowSub;

  /// Current window bounds as (start, end) indices.
  (int, int)? _window;

  /// Timestamp of the last size check in milliseconds since epoch.
  int? _lastSizeCheck;

  /// List of document IDs from the previous window stream to detect additions/removals.
  List<String> _prevWindowIds = [];

  /// Creates a new [CollectionViewer] instance bound to the specified [ModelCrud] collection.
  ///
  /// Initializes the view with default streaming and caching parameters. Immediately emits the initial state via [stream].
  /// Special behavior: Sets up reactive streaming and begins monitoring collection size changes.
  CollectionViewer(
      {required this.crud,
      this.query,
      this.streamWindow = 50,
      this.streamWindowPadding = 9,
      this.memorySize = 512,
      this.limitedSizeDoubleCheckCountThreshold = 10000,
      this.sizeCheckInterval = const Duration(seconds: 30),
      this.streamRetargetCooldown = const Duration(seconds: 3)}) {
    stream.add(this);
  }

  /// Current estimated size of the collection based on cache or recent count query.
  ///
  /// Returns 0 if size is unknown. Triggers size computation if necessary.
  int get size => _cacheSize ?? 0;

  /// Handles updates from the window stream, checking for size changes and emitting the updated view state.
  ///
  /// No parameters. Side effect: May trigger [getSize] if size changed and emits via [stream].
  void _onWindowUpdate() async {
    if (await _hasSizeChanged()) {
      await getSize();
    }

    stream.add(this);
    _log("Stream Updated _onWindowUpdate");
  }

  /// Checks if the collection size has changed since the last check.
  ///
  /// Returns true if size changed or needs recomputation. Uses periodic checks and double-verification for large collections.
  /// No parameters. Throws if Firestore operations fail.
  Future<bool> _hasSizeChanged() async {
    if ((DateTime.now().millisecondsSinceEpoch - (_lastSizeCheck ?? 0)) >
        sizeCheckInterval.inMilliseconds) {
      _lastSizeCheck = DateTime.now().millisecondsSinceEpoch;
    } else {
      return false;
    }

    if (_cacheSize == null) {
      _log(
          "Tried to size check but diddnt have a cached size so getting size now.");
      await getSize();
      return false;
    }

    if (_cacheSize! > limitedSizeDoubleCheckCountThreshold) {
      int size = await getSize();
      int newSize = await _q.limit(size + 1).count();

      if (newSize != size) {
        _cacheSize = null;
        _log("Size Changed: $size -> ~$newSize, wiping size cache.");
        return true;
      }

      return false;
    } else {
      _log(
          "Size Changed: last cache size under $limitedSizeDoubleCheckCountThreshold, so just checking size again...");
      int size = await getSize();
      _cacheSize = null;
      int newSize = await getSize();
      return size != newSize;
    }
  }

  /// Schedules an update to the stream window with throttling to prevent excessive retargeting.
  ///
  /// No parameters. Side effect: Triggers [_updateStreamWindow] after cooldown.
  void updateStreamWindow() =>
      throttle("_windowupdate.${crud.hashCode}", () => _updateStreamWindow(),
          cooldown: streamRetargetCooldown, leaky: true);

  /// Updates the active streaming window based on the current [_lastIndex] and padding.
  ///
  /// Closes invalid windows and opens new ones as needed. Listens for stream changes to update cache and detect size modifications.
  /// No parameters. Throws if Firestore stream setup fails. Side effects: Modifies cache, [_window], and emits via [stream].
  Future<void> _updateStreamWindow() async {
    if (_window != null) {
      if (_lastIndex >= _window!.$1 + _window!.$2 - streamWindowPadding ||
          _lastIndex < _window!.$1 - streamWindowPadding) {
        _log(
            "Window: [${_window!.$1} to ${_window!.$2}] is out of bounds: [${_lastIndex} to ${_lastIndex + streamWindow}] with padding $streamWindowPadding. Closing current window.");
        _window = null;
        _windowSub?.cancel();
      }
    }

    if (_window == null) {
      int start = max(_lastIndex - streamWindow + streamWindowPadding, 0);

      if (_indexCache[start] != null) {
        _window = (start, start + streamWindow);
        await getAt(start);
        _windowStream =
            _q.startAt(_indexCache[start]!).limit(streamWindow).stream;

        _windowSub = _windowStream!.listen((List<DocumentSnapshot> event) {
          _log(
              "Window: [${_window!.$1} to ${_window!.$2}] received stream update.");
          int g = 0;
          Set<String> currentIds = event.map((i) => i.id).toSet();
          bool sizeChange = false;

          for (String prevId in _prevWindowIds) {
            if (!currentIds.contains(prevId)) {
              _indexCache.removeWhere((key, value) => value.id == prevId);
              sizeChange = true;
              _log("Stream detected removal: $prevId (SIZE CHANGED)");
            }
          }
          for (DocumentSnapshot i in event) {
            if (!_prevWindowIds.contains(i.id)) {
              sizeChange = true;
              _log("Stream detected addition: ${i.id} (SIZE CHANGED)");
            }
          }

          for (DocSnap i in event) {
            capture(_window!.$1 + g++, i);
          }

          _prevWindowIds = currentIds.toList(); // Update tracker

          if (sizeChange) {
            _log("Size Changed, clearing cache.");
            clear();
          }
          _onWindowUpdate();
        });

        _log("Window: [${_window!.$1} to ${_window!.$2}] opened in stream.");
      } else {
        _log("No valid start index found for window, not opening stream.");
      }
    }
  }

  /// Invalidates and recomputes the collection size.
  ///
  /// No parameters. Returns a [Future] that completes when size is updated. Side effect: Sets [_cacheSize].
  Future<void> updateSize() {
    _cacheSize = null;
    return getSize();
  }

  /// Clears all caches, resets indices, and reinitializes the view to index 0.
  ///
  /// No parameters. Returns a [Future] that completes after pulling the first document and updating the stream window.
  /// Side effects: Empties [_indexCache], resets [_lastIndex] and [_cacheSize], triggers [updateStreamWindow].
  Future<void> clear() async {
    _log("Clearing Caches & Data");
    _lastIndex = 0;
    _indexCache.clear();
    await getAt(_lastIndex);
    _cacheSize = null;
    updateStreamWindow();
  }

  /// Removes a document from the cache by its ID.
  ///
  /// If found, removes the corresponding index entry and updates the stream window. Returns true if removed.
  /// Parameter: id - The document ID to remove.
  bool removeId(String id) {
    int? index = _indexCache.firstKeyWhere((v) => v.id == id);

    if (index != null) {
      return removeIndex(index);
    }

    return false;
  }

  /// Removes a document from the cache by its index.
  ///
  /// Updates the stream window if removed. Returns true if the index existed.
  /// Parameter: index - The index to remove.
  bool removeIndex(int index) {
    if (_indexCache.remove(index) != null) {
      _log("Removing Index: $index");
      updateStreamWindow();
      return true;
    }

    return false;
  }

  /// Updates a document in the cache by its ID via a fresh Firestore get.
  ///
  /// If found, refreshes the snapshot and updates the stream window. Returns true if updated.
  /// Parameter: id - The document ID to update.
  Future<bool> updateId(String id) {
    int? index = _indexCache.firstKeyWhere((v) => v.id == id);

    if (index != null) {
      _log("Updating Index: $index");
      return updateIndex(index);
    }

    return Future.value(false);
  }

  /// Updates a document in the cache by its index via a fresh Firestore get.
  ///
  /// Refreshes the snapshot if it exists and updates the stream window. Returns true if updated.
  /// Parameter: index - The index to update.
  Future<bool> updateIndex(int index) {
    if (hasSnapshot(index)) {
      return _indexCache[index]!
          .reference
          .get()
          .then((value) => capture(index, value))
          .then((value) => updateStreamWindow())
          .then((value) => true);
    }

    return Future.value(false);
  }

  /// Retrieves or fetches the model at the specified index, updating the last index and stream window.
  ///
  /// Uses cache if available; otherwise pulls smartly from nearest known snapshot. Returns the [T] model or null if not found.
  /// Parameter: index - The index to retrieve.
  /// Throws if Firestore operations fail. Side effects: Updates [_lastIndex] and triggers [updateStreamWindow].
  Future<T?> getAt(int index) => lock.synchronized(() async {
        _lastIndex = index;

        if (hasSnapshot(index)) {
          return getCachedAt(index);
        }

        await pullSmart(index);
        updateStreamWindow();
        return getCachedAt(index);
      });

  /// Computes the cache distance to the nearest snapshot from the given index.
  ///
  /// Returns the absolute distance or null if no nearest snapshot found.
  /// Parameter: index - The target index.
  Future<int?> cacheDistance(int index) async {
    (int, DocSnap)? closest = await nearestTo(index);

    if (closest != null) {
      return (closest.$1 - index).abs();
    }

    return null;
  }

  /// Retrieves the cached model at the specified index, converting the snapshot to [T].
  ///
  /// Returns null if no snapshot or if it doesn't exist.
  /// Parameter: index - The index to retrieve from cache.
  T? getCachedAt(int index) {
    try {
      DocSnap? r = _indexCache[index];
      r = (r?.exists ?? false) ? r : null;
      return r != null ? crud.getCrud<T>().withPath(r.data, r.path) : null;
    } catch (e) {
      return null;
    }
  }

  /// Logs a message if [kCollectionViewerDebug] is enabled.
  ///
  /// No parameters. Side effect: Prints to console if debug enabled.
  void _log(String s) {
    if (kCollectionViewerDebug) {
      print("[${runtimeType.toString()}]: $s");
    }
  }

  /// Computes and caches the size of the collection using Firestore count.
  ///
  /// Returns the size. Initializes empty listener if size is 0. Throws if count fails.
  /// No parameters. Side effects: Sets [_cacheSize] and potentially [_emptyListener].
  Future<int> getSize() async {
    int? sizesc = _cacheSize;
    _cacheSize ??= await _q.count().thenRun((v) => _log("Size Captured: $v"));

    if (sizesc == _cacheSize) {
      return _cacheSize!;
    }

    if (_cacheSize != null && _cacheSize! < 1) {
      _lastIndex = 0;
      _indexCache.clear();
      bool expectedEmpty = true;
      _emptyListener ??= _q
          .limit(1)
          .stream
          .map((event) => event.isNotEmpty)
          .listen((nonEmpty) {
        if (expectedEmpty && nonEmpty) {
          expectedEmpty = false;
          _cacheSize = null;
          _emptyListener?.cancel();
          _emptyListener = null;
          _onWindowUpdate();
        } else {
          expectedEmpty =
              false; // Initial was already non-empty (raced add) or became empty (ignore)
        }
      });
    }

    return _cacheSize!;
  }

  /// Finds the nearest cached snapshot to the given index using a zig-zag search pattern.
  ///
  /// Returns (index, snapshot) pair or null if none found. Initializes cache with first document if empty.
  /// Parameter: index - The target index.
  /// Throws if Firestore get fails. Side effect: May populate initial cache entry.
  Future<(int, DocSnap)?> nearestTo(int index) async {
    if (_indexCache.isEmpty) {
      await _q.limit(1).get().then((value) {
        if (value.isEmpty) {
          return;
        }

        _indexCache[0] = value[0];
      });
    }

    if (_indexCache.isEmpty) {
      return null;
    }

    int size = await getSize();

    for (int i in zigZag()) {
      int id = index + i;

      if (id < -1 || id > size + 1) {
        break;
      }

      if (_indexCache.containsKey(id)) {
        return (id, _indexCache[id]!);
      }
    }

    return null;
  }

  /// Cleans up distant cache entries beyond [memorySize] from [_lastIndex].
  ///
  /// No parameters. Side effect: Removes entries from [_indexCache] and logs cleanup.
  void cleanup() {
    int l = _indexCache.length;

    _indexCache
        .removeWhere((key, value) => (key - _lastIndex).abs() > memorySize);
    _log("Cleanup: $l -> ${_indexCache.length}");
  }

  /// Stores a snapshot at the specified index in the cache.
  ///
  /// No return value. Side effect: Updates [_indexCache].
  /// Parameters: index - The index to store at; ref - The [DocumentSnapshot] to cache.
  void capture(int index, DocSnap ref) {
    _indexCache[index] = ref;
  }

  /// Getter for the underlying queried [CollectionReference].
  ///
  /// Applies [query] if provided; otherwise uses the raw collection from [crud].
  _Q get _q =>
      query?.call(
          FirestoreDatabase.instance.collection(crud.parentCollectionPath!)) ??
      FirestoreDatabase.instance.collection(crud.parentCollectionPath!);

  /// Checks if a snapshot exists in the cache for the given index.
  ///
  /// Parameter: index - The index to check. Returns true if cached.
  bool hasSnapshot(int index) => _indexCache.containsKey(index);

  /// Intelligently pulls documents around the target index using nearest snapshot.
  ///
  /// Determines direction and count based on distance, then calls appropriate pull method. No return value.
  /// Parameter: index - The target index to pull towards.
  /// Throws if Firestore queries fail. Side effect: Populates [_indexCache].
  Future<void> pullSmart(int index) async {
    (int, DocSnap)? snap = await nearestTo(index);

    if (snap == null) {
      return;
    }

    if (index < snap.$1) {
      _log(
          "PullSmart: INDEX $index is < ${snap.$1}. Pulling ref=${snap.$1}, (ref-index+streamwindow = ${snap.$1} - $index + $streamWindow) = ${snap.$1 - index + streamWindow})");
      return pullPreviousCountSmart(
          snap.$1, snap.$2, snap.$1 - index + streamWindow);
    } else {
      _log(
          "PullSmart: INDEX $index is >= ${snap.$1}. Pulling ref=${snap.$1}, (index - ref + streamWindow = $index - ${snap.$1} + $streamWindow) = ${index - snap.$1 + streamWindow})");
      return pullNextCountSmart(
          snap.$1, snap.$2, index - snap.$1 + streamWindow);
    }
  }

  /// Smartly pulls a count of previous documents, skipping over already cached ones.
  ///
  /// Batches pulls between cached points for efficiency. No return value.
  /// Parameters: refIndex - Starting index; ref - Starting snapshot; cnt - Number to pull.
  /// Throws if Firestore queries fail. Side effect: Populates [_indexCache].
  Future<void> pullPreviousCountSmart(int refIndex, DocSnap ref, int cnt) {
    if (cnt < 1) {
      return Future.value();
    }

    List<Future> f = [];
    int atIndex = refIndex;
    DocSnap atSnap = ref;
    int count = 0;
    for (int i = refIndex - 1; i > refIndex - cnt; i--) {
      if (!hasSnapshot(i)) {
        count++;
        continue;
      } else if (count > 0) {
        f.add(pullPreviousCount(atIndex, atSnap, count));
      }

      count = 0;
      atIndex = i;
      atSnap = _indexCache[i]!;
    }

    if (f.isEmpty) {
      f.add(pullPreviousCount(atIndex, atSnap, cnt));
    }

    _log("Pulling Previous Count Smart: $refIndex x$cnt");

    return Future.wait(f);
  }

  /// Smartly pulls a count of next documents, skipping over already cached ones.
  ///
  /// Batches pulls between cached points for efficiency. No return value.
  /// Parameters: refIndex - Starting index; ref - Starting snapshot; cnt - Number to pull.
  /// Throws if Firestore queries fail. Side effect: Populates [_indexCache].
  Future<void> pullNextCountSmart(int refIndex, DocSnap ref, int cnt) {
    if (cnt < 1) {
      _log("PullNextCountSmart: Count is less than 1, nothing to pull.");
      return Future.value();
    }

    List<Future> f = [];
    int atIndex = refIndex;
    DocSnap atSnap = ref;
    int count = 0;
    for (int i = refIndex + 1; i < refIndex + cnt; i++) {
      if (!hasSnapshot(i)) {
        count++;
        continue;
      } else if (count > 0) {
        f.add(pullNextCount(atIndex, atSnap, count));
      }

      count = 0;
      atIndex = i;
      atSnap = _indexCache[i]!;
    }

    if (f.isEmpty) {
      f.add(pullNextCount(atIndex, atSnap, cnt));
    }

    _log("Pulling Next Count Smart: $refIndex x$cnt");
    return Future.wait(f);
  }

  /// Pulls a specified count of documents before the reference snapshot.
  ///
  /// Populates cache with fetched snapshots in reverse order. No return value.
  /// Parameters: refIndex - Reference index; ref - Reference snapshot; count - Number to pull.
  /// Throws if Firestore get fails. Side effect: Populates [_indexCache].
  Future<void> pullPreviousCount(int refIndex, DocSnap ref, int count) async {
    if (count < 1) {
      return Future.value();
    }

    int at = refIndex - 1;
    for (DocSnap i in await _q.endBefore(ref).limit(count).get()) {
      capture(at--, i);
    }

    _log(
        "Pulled Previous Count: $refIndex x$count (end before ${ref.id}, limit $count)");
  }

  /// Pulls a specified count of documents after the reference snapshot.
  ///
  /// Populates cache with fetched snapshots in order. No return value.
  /// Parameters: refIndex - Reference index; ref - Reference snapshot; count - Number to pull.
  /// Throws if Firestore get fails. Side effect: Populates [_indexCache].
  Future<void> pullNextCount(int refIndex, DocSnap ref, int count) async {
    if (count < 1) {
      return Future.value();
    }

    int at = refIndex + 1;
    for (DocSnap i in await _q.startAfter(ref).limit(count).get()) {
      capture(at++, i);
    }

    _log(
        "Pulled Next Count: $refIndex x$count (start after ${ref.id}, limit $count)");
  }

  /// Pulls the single previous document before the reference.
  ///
  /// Convenience wrapper for [pullPreviousCount] with count 1. No return value.
  /// Parameters: refIndex - Reference index; ref - Reference snapshot.
  Future<void> pullPrevious(int refIndex, DocSnap ref) =>
      pullPreviousCount(refIndex, ref, 1);

  /// Pulls the single next document after the reference.
  ///
  /// Convenience wrapper for [pullNextCount] with count 1. No return value.
  /// Parameters: refIndex - Reference index; ref - Reference snapshot.
  Future<void> pullNext(int refIndex, DocSnap ref) =>
      pullNextCount(refIndex, ref, 1);

  /// Generates a zig-zag sequence of offsets starting from 0, alternating positive and negative.
  ///
  /// Used for searching nearest cache entries. Yields integers indefinitely.
  Iterable<int> zigZag() sync* {
    int i = 0;
    while (true) {
      yield i;
      if (i > 0) {
        i = -i;
      } else {
        i = -i + 1;
      }
    }
  }

  /// Closes the viewer, releasing all resources.
  ///
  /// No parameters. Side effects: Cancels subscriptions, clears cache and indices, sets streams to null.
  void close() {
    _lastIndex = 0;
    _indexCache.clear();
    _windowSub?.cancel();
    _windowStream = null;
    _window = null;
  }
}
