import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fire_crud/fire_crud.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';
import 'package:throttled/throttled.dart';
import 'package:toxic/toxic.dart';

typedef DocSnap = DocumentSnapshot<Map<String, dynamic>>;
typedef DocRef = DocumentReference<Map<String, dynamic>>;
typedef _Q = Query<Map<String, dynamic>>;
typedef _QStream = Stream<QuerySnapshot<Map<String, dynamic>>>;
typedef _QSub = StreamSubscription<QuerySnapshot<Map<String, dynamic>>>;

class CollectionViewer<T> {
  final FireCrud<T> crud;
  final QueryBuilder? query;
  final int streamWindow;
  final int streamWindowPadding;
  final int memorySize;
  final Map<int, DocSnap> _indexCache = {};
  final Duration streamRetargetCooldown;
  final Duration sizeCheckInterval;
  final int limitedSizeDoubleCheckCountThreshold;
  final BehaviorSubject<CollectionViewer<T>> stream = BehaviorSubject();
  final Lock lock = Lock();
  int _lastIndex = 0;
  int? _cacheSize;
  _QStream? _windowStream;
  _QSub? _windowSub;
  (int, int)? _window;
  int? _lastSizeCheck;

  CollectionViewer(
      {required this.crud,
      this.query,
      this.streamWindow = 50,
      this.streamWindowPadding = 9,
      this.memorySize = 256,
      this.limitedSizeDoubleCheckCountThreshold = 10000,
      this.sizeCheckInterval = const Duration(seconds: 30),
      this.streamRetargetCooldown = const Duration(seconds: 3)}) {
    stream.add(this);
  }

  int get size => _cacheSize ?? 0;

  void _onWindowUpdate() async {
    if (await _hasSizeChanged()) {
      await getSize();
    }

    stream.add(this);
    _log("Stream Updated _onWindowUpdate");
  }

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
      int newSize = await _q
          .limit(size + 1)
          .count()
          .get()
          .then((value) => value.count ?? 0);

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

  void updateStreamWindow() =>
      throttle("_windowupdate.${crud.hashCode}", () => _updateStreamWindow(),
          cooldown: streamRetargetCooldown, leaky: true);

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
      _window = (start, start + streamWindow);
      await getAt(start);
      _windowStream = _q
          .startAtDocument(_indexCache[start]!)
          .limit(streamWindow)
          .snapshots();
      _windowSub = _windowStream!.listen((event) {
        _log(
            "Window: [${_window!.$1} to ${_window!.$2}] received stream update.");
        int g = 0;
        for (DocSnap i in event.docs) {
          capture(start + g++, i);
        }

        _onWindowUpdate();
      });

      _log("Window: [${_window!.$1} to ${_window!.$2}] opened in stream.");
    }
  }

  Future<void> updateSize() {
    _cacheSize = null;
    return getSize();
  }

  Future<void> clear() async {
    _log("Clearing Caches & Data");
    _lastIndex = 0;
    _indexCache.clear();
    await getAt(_lastIndex);
    updateStreamWindow();
  }

  bool removeId(String id) {
    int? index = _indexCache.firstKeyWhere((v) => v.id == id);

    if (index != null) {
      return removeIndex(index);
    }

    return false;
  }

  bool removeIndex(int index) {
    if (_indexCache.remove(index) != null) {
      _log("Removing Index: $index");
      updateStreamWindow();
      return true;
    }

    return false;
  }

  Future<bool> updateId(String id) {
    int? index = _indexCache.firstKeyWhere((v) => v.id == id);

    if (index != null) {
      _log("Updating Index: $index");
      return updateIndex(index);
    }

    return Future.value(false);
  }

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

  Future<T?> getAt(int index) => lock.synchronized(() async {
        _lastIndex = index;

        if (hasSnapshot(index)) {
          return getCachedAt(index);
        }

        await pullSmart(index);
        updateStreamWindow();
        return getCachedAt(index);
      });

  Future<int?> cacheDistance(int index) async {
    (int, DocSnap)? closest = await nearestTo(index);

    if (closest != null) {
      return (closest.$1 - index).abs();
    }

    return null;
  }

  T? getCachedAt(int index) {
    try {
      DocSnap? r = _indexCache[index];
      r = (r?.exists ?? false) ? r : null;
      return r != null ? crud.fromMap(r.id, r.data() ?? {}) : null;
    } catch (e, es) {
      return null;
    }
  }

  void _log(String s) {
    // print("[${runtimeType.toString()}]: $s");
  }

  Future<int> getSize() async {
    _cacheSize ??= await _q
        .count()
        .get()
        .then((value) => value.count ?? 0)
        .thenRun((v) => _log("Size Captured: $v"));
    return _cacheSize!;
  }

  Future<(int, DocSnap)?> nearestTo(int index) async {
    if (_indexCache.isEmpty) {
      await _q.limit(1).get().then((value) {
        if (value.docs.isEmpty) {
          return;
        }

        _indexCache[0] = value.docs[0];
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

  void cleanup() {
    int l = _indexCache.length;

    _indexCache
        .removeWhere((key, value) => (key - _lastIndex).abs() > memorySize);
    _log("Cleanup: $l -> ${_indexCache.length}");
  }

  void capture(int index, DocSnap ref) {
    _indexCache[index] = ref;
  }

  _Q get _q => crud.applyQueryBuilder(query);

  bool hasSnapshot(int index) => _indexCache.containsKey(index);

  Future<void> pullSmart(int index) async {
    (int, DocSnap)? snap = await nearestTo(index);

    if (snap == null) {
      return;
    }

    if (index < snap.$1) {
      return pullPreviousCountSmart(
          snap.$1, snap.$2, snap.$1 - index + streamWindow);
    } else {
      return pullNextCountSmart(
          snap.$1, snap.$2, index - snap.$1 + streamWindow);
    }
  }

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

  Future<void> pullNextCountSmart(int refIndex, DocSnap ref, int cnt) {
    if (cnt < 1) {
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

  Future<void> pullPreviousCount(int refIndex, DocSnap ref, int count) async {
    if (count < 1) {
      return Future.value();
    }

    int at = refIndex - 1;
    for (DocSnap i in await _q
        .endBeforeDocument(ref)
        .limit(count)
        .get()
        .then((value) => value.docs)) {
      capture(at--, i);
    }

    _log(
        "Pulled Previous Count: $refIndex x$count (end before ${ref.id}, limit $count)");
  }

  Future<void> pullNextCount(int refIndex, DocSnap ref, int count) async {
    if (count < 1) {
      return Future.value();
    }

    int at = refIndex + 1;
    for (DocSnap i in await _q
        .startAfterDocument(ref)
        .limit(count)
        .get()
        .then((value) => value.docs)) {
      capture(at++, i);
    }

    _log(
        "Pulled Next Count: $refIndex x$count (start after ${ref.id}, limit $count)");
  }

  Future<void> pullPrevious(int refIndex, DocSnap ref) =>
      pullPreviousCount(refIndex, ref, 1);

  Future<void> pullNext(int refIndex, DocSnap ref) =>
      pullNextCount(refIndex, ref, 1);

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

  void close() {
    _lastIndex = 0;
    _indexCache.clear();
    _windowSub?.cancel();
    _windowStream = null;
    _window = null;
  }
}
