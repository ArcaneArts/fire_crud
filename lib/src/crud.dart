import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection_walker/collection_walker.dart';
import 'package:fire_crud/fire_crud.dart';
import 'package:fire_crud/src/collection_view.dart';
import 'package:flutter/material.dart';

typedef QueryBuilder = Query<Map<String, dynamic>> Function(
  CollectionReference<Map<String, dynamic>> collection,
);

class FireCrud<T> {
  final CollectionReference<Map<String, dynamic>> collection;
  final Map<String, dynamic> Function(T t) toMap;
  final T Function(String id, Map<String, dynamic> map) fromMap;
  final T? emptyObject;
  final void Function(FireCrudEvent event)? usageTracker;

  /// If shared is enabled & there is an active stream sharer instance
  /// Then the stream will be act as a proxy broadcast stream preventing duplicate streams for the same query
  final bool shared;

  FireCrud(
      {required this.collection,
      required this.toMap,
      required this.fromMap,
      this.usageTracker,
      this.emptyObject,
      this.shared = true});

  Stream<X> _share<X>(Stream<X> firestore,
          {DocumentReference? doc, CollectionReference? col, Query? q}) =>
      shared && FireStreamSharer.activeSharer != null
          ? FireStreamSharer.activeSharer!
              .streamFor(firestore, doc: doc, col: col, q: q)
              .getListener()
          : firestore;

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
    QueryBuilder? query,
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
    QueryBuilder? query,
  }) =>
      _share(
          applyQueryBuilder(query).snapshots().map((event) {
            _track(readObjects: event.docs);
            return event.docs.map((e) => fromMap(e.id, e.data()));
          }),
          col: collection,
          q: applyQueryBuilder(query));

  Future<Iterable<T>> getAll({
    QueryBuilder? query,
  }) =>
      applyQueryBuilder(query).get().then((value) {
        _track(readObjects: value.docs);
        return value.docs.map((e) => fromMap(e.id, e.data()));
      });

  CollectionWalker<T> walk({
    QueryBuilder? query,
    CollectionBatchListener? batchListener,
    int chunkSize = 50,
  }) =>
      CollectionWalker(
          query: applyQueryBuilder(query),
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

  Future<T> getCached(String id) => collection
          .doc(id)
          .get(
            const GetOptions(source: Source.cache),
          )
          .catchError((e, es) => collection.doc(id).get())
          .then((value) {
        _track(read: value);
        return fromMap(
            value.id,
            value.data() ??
                (emptyObject == null ? {} : toMap(emptyObject as T)));
      });

  Future<DocumentSnapshot<Map<String, dynamic>>> getRaw(String id) =>
      collection.doc(id).get().then((value) {
        _track(read: value);
        return value;
      });

  Future<T> get(String id) => getRaw(id).then((value) => fromMap(value.id,
      value.data() ?? (emptyObject == null ? {} : toMap(emptyObject as T))));

  Future<T?> getOrNull(String id) => getRaw(id)
      .then((value) => value.exists ? fromMap(value.id, value.data()!) : null);

  Stream<T?> streamOrNull(String id) => _share(
        collection.doc(id).snapshots().map((value) {
          _track(read: value);
          return value.exists ? fromMap(value.id, value.data()!) : null;
        }),
        doc: collection.doc(id),
      );

  Stream<T> streamOrReturn(String id, T Function() or) =>
      streamOrNull(id).map((event) => event ?? or());

  Stream<T> stream(String id) => streamOrNull(id).map((event) =>
      event ?? fromMap(id, emptyObject == null ? {} : toMap(emptyObject as T)));

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

  Future<void> txn(String id, T Function(T data) write) =>
      FirebaseFirestore.instance
          .runTransaction((transaction) => transaction
              .get(collection.doc(id))
              .then((value) => fromMap(
                  value.id,
                  value.data() ??
                      (emptyObject == null ? {} : toMap(emptyObject as T))))
              .then((value) =>
                  transaction.set(collection.doc(id), toMap(write(value)))))
          .then((value) => _track(
                reads: 1,
                writes: 1,
              ));

  Future<void> set(String id, T data) =>
      collection.doc(id).set(toMap(data)).then((value) {
        _track(writes: 1);
        return value;
      });

  Query<Map<String, dynamic>> applyQueryBuilder(QueryBuilder? query) =>
      query?.call(collection) ?? collection;

  Future<int> count({
    QueryBuilder? query,
  }) =>
      applyQueryBuilder(query).count().get().then((value) {
        _track(aggregation: value.count ?? 0);

        return value.count ?? 0;
      });

  Future<String> add(T data) =>
      collection.add(toMap(data)).then((value) => value.id);
}
