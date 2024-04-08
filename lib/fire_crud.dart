library fire_crud;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection_walker/collection_walker.dart';
import 'package:flutter/material.dart';

double kFireCrudCostPerRead = 0.0345 / 100000.0;
double kFireCrudCostPerWrite = 0.1042 / 100000.0;
double kFireCrudCostPerDelete = 0.0115 / 100000.0;

class FireCrudEvent {
  final int reads;
  final int writes;
  final int deletes;

  FireCrudEvent({this.reads = 0, this.writes = 0, this.deletes = 0});

  FireCrudEvent operator +(FireCrudEvent other) => FireCrudEvent(
        reads: reads + other.reads,
        writes: writes + other.writes,
        deletes: deletes + other.deletes,
      );

  double get cost =>
      (reads * kFireCrudCostPerRead) +
      (writes * kFireCrudCostPerWrite) +
      (deletes * kFireCrudCostPerDelete);
}

class FireCrud<T> {
  final CollectionReference<Map<String, dynamic>> collection;
  final Map<String, dynamic> Function(T t) toMap;
  final T Function(String id, Map<String, dynamic> map) fromMap;
  final T? emptyObject;
  final void Function(FireCrudEvent event)? usageTracker;

  FireCrud({
    required this.collection,
    required this.toMap,
    required this.fromMap,
    this.usageTracker,
    this.emptyObject,
  });

  void _track(
      {List<DocumentSnapshot<Map<String, dynamic>>>? readObjects,
      int reads = 0,
      int writes = 0,
      int deletes = 0,
      DocumentSnapshot<Map<String, dynamic>>? read,
      int? aggregation}) {
    if (usageTracker == null) {
      return;
    }

    if (aggregation != null) {
      reads += aggregation > 0 ? (aggregation.toDouble() / 1000.0).ceil() : 1;
    }

    if (read != null) {
      if (!read.metadata.isFromCache) {
        reads++;
      }
    }

    if (readObjects != null) {
      for (var obj in readObjects) {
        if (obj.exists && !obj.metadata.isFromCache) {
          reads++;
        }
      }
    }

    usageTracker
        ?.call(FireCrudEvent(reads: reads, writes: writes, deletes: deletes));
  }

  Widget streamBuilder({
    Query<Map<String, dynamic>> Function(
      CollectionReference<Map<String, dynamic>> collection,
    )? query,
    required Widget Function(BuildContext context, T data) builder,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    Widget Function(BuildContext context)? loading,
    Widget Function(BuildContext context)? empty,
  }) =>
      StreamBuilder<Iterable<T>>(
          stream: streamAll(query: query),
          builder: (context, snap) => snap.hasData
              ? snap.data!.isEmpty
                  ? (empty?.call(context) ?? Container())
                  : ListView.builder(
                      itemCount: snap.data!.length,
                      itemBuilder: (context, index) =>
                          builder(context, snap.data!.elementAt(index)),
                      shrinkWrap: shrinkWrap,
                      physics: physics,
                    )
              : (loading?.call(context) ?? Container()));

  Stream<Iterable<T>> streamAll({
    Query<Map<String, dynamic>> Function(
      CollectionReference<Map<String, dynamic>> collection,
    )? query,
  }) =>
      _q(query).snapshots().map((event) {
        _track(readObjects: event.docs);
        return event.docs.map((e) => fromMap(e.id, e.data()));
      });

  Future<Iterable<T>> getAll({
    Query<Map<String, dynamic>> Function(
      CollectionReference<Map<String, dynamic>> collection,
    )? query,
  }) =>
      _q(query).get().then((value) {
        _track(readObjects: value.docs);
        return value.docs.map((e) => fromMap(e.id, e.data()));
      });

  CollectionWalker<T> walk({
    Query<Map<String, dynamic>> Function(
      CollectionReference<Map<String, dynamic>> collection,
    )? query,
    CollectionBatchListener? batchListener,
    int chunkSize = 50,
  }) =>
      CollectionWalker(
          query: _q(query),
          chunkSize: chunkSize,
          batchListener: (batch) {
            _track(readObjects: batch);
            return batchListener?.call(batch) ?? batch;
          },
          documentConverter: (doc) async => fromMap(doc.id, doc.data()!));

  Future<bool> exists(String id) => collection.doc(id).get().then((value) {
        _track(read: value);
        return value.exists;
      });

  Future<void> delete(String id) =>
      collection.doc(id).delete().then((value) => _track(deletes: 1));

  Future<T> get(String id) => collection.doc(id).get().then((value) {
        _track(read: value);
        return fromMap(
            value.id,
            value.data() ??
                (emptyObject == null ? {} : toMap(emptyObject as T)));
      });

  Future<T?> getOrNull(String id) => collection.doc(id).get().then((value) {
        _track(read: value);
        return value.exists ? fromMap(value.id, value.data()!) : null;
      });

  Stream<T?> streamOrNull(String id) =>
      collection.doc(id).snapshots().map((value) {
        _track(read: value);
        return value.exists ? fromMap(value.id, value.data()!) : null;
      });

  Stream<T> streamOrReturn(String id, T Function() or) =>
      collection.doc(id).snapshots().map((value) {
        _track(read: value);
        return value.exists ? fromMap(value.id, value.data()!) : or();
      });

  Stream<T> stream(String id) => collection.doc(id).snapshots().map((value) {
        _track(read: value);
        return fromMap(
            value.id,
            value.data() ??
                (emptyObject == null ? {} : toMap(emptyObject as T)));
      });

  Future<T> getOrReturn(String id, T Function() or) =>
      getOrNull(id).then((value) => value ?? or());

  Future<T> getOrSet(String id, T Function() or) =>
      collection.doc(id).get().then((value) {
        _track(read: value);

        if (value.exists) {
          set(id, or());
        }
        return fromMap(value.id, value.data()!);
      });

  Future<void> setIfAbsent(String id, T Function() or) =>
      exists(id).then((value) {
        if (!value) {
          set(id, or());
        }
      });

  Future<void> update(String id, Map<String, dynamic> data) =>
      collection.doc(id).update(data).then((value) {
        _track(writes: 1);
        return value;
      });

  Future<void> set(String id, T data) =>
      collection.doc(id).set(toMap(data)).then((value) {
        _track(writes: 1);
        return value;
      });

  Query<Map<String, dynamic>> _q(
          Query<Map<String, dynamic>> Function(
            CollectionReference<Map<String, dynamic>> collection,
          )? query) =>
      query?.call(collection) ?? collection;

  Future<int> count({
    Query<Map<String, dynamic>> Function(
      CollectionReference<Map<String, dynamic>> collection,
    )? query,
  }) =>
      _q(query).count().get().then((value) {
        _track(aggregation: value.count ?? 0);

        return value.count ?? 0;
      });

  Future<String> add(T data) =>
      collection.add(toMap(data)).then((value) => value.id);
}
