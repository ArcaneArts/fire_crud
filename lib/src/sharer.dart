import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:toxic/extensions/map.dart';

class SharedFireStream<T> {
  late String key;
  late Stream<T> stream;
  late StreamSubscription<T> subscription;
  late List<BehaviorSubject<T>> activeListeners;
  bool active = true;
  T? lastValue;

  SharedFireStream(this.key, this.stream) {
    activeListeners = [];
    subscription = stream.listen((event) {
      lastValue = event;
      for (var listener in activeListeners) {
        listener.add(event);
      }
    });
  }

  void _onBehaviorOpen(BehaviorSubject<T> bs) {
    activeListeners.add(bs);
  }

  void _onBehaviorClose(BehaviorSubject<T> bs) {
    activeListeners.remove(bs);
    if (activeListeners.isEmpty) {
      subscription.cancel();
    }
  }

  BehaviorSubject<T> getListener() {
    late BehaviorSubject<T> bs;
    bs = lastValue != null
        ? BehaviorSubject.seeded(lastValue as T,
            onCancel: () => _onBehaviorClose(bs),
            onListen: () => _onBehaviorOpen(bs))
        : BehaviorSubject(
            onCancel: () => _onBehaviorClose(bs),
            onListen: () => _onBehaviorOpen(bs));

    activeListeners.add(bs);
    return bs;
  }

  void onListen(BehaviorSubject<T> listener) {
    activeListeners.add(listener);
  }
}

class FireStreamSharer {
  static FireStreamSharer? activeSharer;

  Map<String, SharedFireStream> streams = {};

  SharedFireStream<T> streamFor<T>(Stream<T> firestore,
          {DocumentReference? doc, CollectionReference? col, Query? q}) =>
      streams.computeIfAbsent(
          "$T:${(doc?.path ?? col?.path)!}${q != null ? "?${q.parameters.toString()}" : ""}",
          (key) => SharedFireStream<T>(key, firestore)) as SharedFireStream<T>;
}
