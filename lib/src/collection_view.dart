import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fire_crud/fire_crud.dart';
import 'package:rxdart/rxdart.dart';
import 'package:toxic/extensions/map.dart';

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
  final Duration requestGroupTime;
  final Duration sizeCheckInterval;
  final int limitedSizeDoubleCheckCountThreshold;
  final BehaviorSubject<CollectionViewer<T>> stream = BehaviorSubject();
  int _lastIndex = 0;
  int? _cacheSize;
  Set<int> _requested = {};
  bool _requesting = false;
  Completer<bool> _requestCompleter = Completer();
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
      this.requestGroupTime = const Duration(milliseconds: 50)}) {
    stream.add(this);
  }

  int get size => _cacheSize ?? 0;

  void _onWindowUpdate() async {
    if (await _hasSizeChanged()) {
      await getSize();
    }

    stream.add(this);
  }

  Future<bool> _hasSizeChanged() async {
    if ((DateTime.now().millisecondsSinceEpoch - (_lastSizeCheck ?? 0)) >
        sizeCheckInterval.inMilliseconds) {
      _lastSizeCheck = DateTime.now().millisecondsSinceEpoch;
    } else {
      return false;
    }

    if (_cacheSize == null) {
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
        return true;
      }

      return false;
    } else {
      int size = await getSize();
      _cacheSize = null;
      int newSize = await getSize();
      return size != newSize;
    }
  }

  Future<void> updateStreamWindow() async {
    if (_window != null) {
      if (_lastIndex >= _window!.$1 + _window!.$2 - streamWindowPadding ||
          _lastIndex < _window!.$1 - streamWindowPadding) {
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
        int g = 0;
        for (DocSnap i in event.docs) {
          capture(start + g++, i);
        }

        _onWindowUpdate();
      });
    }
  }

  Future<void> updateSize() {
    _cacheSize = null;
    return getSize();
  }

  Future<void> pullRequested() async {
    Map<int, int> distField = {};

    for (int i in _requested) {
      distField[i] = await cacheDistance(i) ?? 0;
    }

    for (int i
        in distField.sortedKeysByValue((ind, dst) => dst.compareTo(ind))) {
      await pullSmart(i);
    }

    _requested.clear();
    updateStreamWindow();
    cleanup();
  }

  Future<void> clear() async {
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
      updateStreamWindow();
      return true;
    }

    return false;
  }

  Future<bool> updateId(String id) {
    int? index = _indexCache.firstKeyWhere((v) => v.id == id);

    if (index != null) {
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

  Future<T?> getAt(int index) {
    _lastIndex = index;

    if (hasSnapshot(index)) {
      return getCachedAt(index);
    }

    _requested.add(index);

    if (!_requesting) {
      _requesting = true;
      _requestCompleter = Completer();
      Future.delayed(
          requestGroupTime,
          () => pullRequested().then((value) {
                _requestCompleter.complete(true);
                _requesting = false;
              }));
    }

    return _requestCompleter.future.then((value) => getCachedAt(index));
  }

  Future<int?> cacheDistance(int index) async {
    (int, DocSnap)? closest = await nearestTo(index);

    if (closest != null) {
      return (closest.$1 - index).abs();
    }

    return null;
  }

  Future<T?> getCachedAt(int index) async {
    DocSnap? r = _indexCache[index];
    r = (r?.exists ?? false) ? r : null;
    return r != null ? crud.fromMap(r.id, r.data() ?? {}) : null;
  }

  Future<int> getSize() async {
    _cacheSize ??= await _q.count().get().then((value) => value.count ?? 0);
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
    _indexCache
        .removeWhere((key, value) => (key - _lastIndex).abs() > memorySize);
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
      return pullPreviousCountSmart(snap.$1, snap.$2, snap.$1 - index);
    } else {
      return pullNextCountSmart(snap.$1, snap.$2, index - snap.$1);
    }
  }

  Future<void> pullPreviousCountSmart(int refIndex, DocSnap ref, int count) {
    List<Future> f = [];
    int atIndex = refIndex;
    DocSnap atSnap = ref;
    int count = 0;
    for (int i = refIndex - 1; i > refIndex - count; i--) {
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

    return Future.wait(f);
  }

  Future<void> pullNextCountSmart(int refIndex, DocSnap ref, int count) {
    List<Future> f = [];
    int atIndex = refIndex;
    DocSnap atSnap = ref;
    int count = 0;
    for (int i = refIndex + 1; i < refIndex + count; i++) {
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

    return Future.wait(f);
  }

  Future<void> pullPreviousCount(int refIndex, DocSnap ref, int count) async {
    int at = refIndex - 1;
    for (DocSnap i in await _q
        .endBeforeDocument(ref)
        .limit(count)
        .get()
        .then((value) => value.docs)) {
      capture(at--, i);
    }
  }

  Future<void> pullNextCount(int refIndex, DocSnap ref, int count) async {
    int at = refIndex + 1;
    for (DocSnap i in await _q
        .startAfterDocument(ref)
        .limit(count)
        .get()
        .then((value) => value.docs)) {
      capture(at++, i);
    }
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
}
