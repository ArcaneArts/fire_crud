// GENERATED – do not modify.
import 'dart:core';

import 'package:example/subtask.dart';
import 'package:example/task.dart';
import 'package:fire_api/fire_api.dart';

/// CRUD Extensions for Task
extension XFCrudBase$Task on Task {
  /// Gets this document (self) live and returns a new instance of [Task] representing the new data
  Future<Task?> get() => getSelfRaw<Task>();

  /// Opens a self stream of [Task] representing this document
  Stream<Task?> stream() => streamSelfRaw<Task>();

  /// Sets this [Task] document to a new value
  Future<void> set(Task to) => setSelfRaw<Task>(to);

  /// Updates properties of this [Task] with {"fieldName": VALUE, ...}
  Future<void> update(Map<String, dynamic> u) => updateSelfRaw<Task>(u);

  /// Deletes this [Task] document
  Future<void> delete() => deleteSelfRaw<Task>();

  /// Sets this [Task] document atomically by getting first then setting.
  Future<void> setAtomic(Task Function(Task?) txn) =>
      setSelfAtomicRaw<Task>(txn);

  Future<void> mutate({
    int? integer,
    double? doub,
    String? str,
    Subtask? subtask,
    DateTime? date,
    List<Subtask>? addSubtasks,
    List<Subtask>? removeSubtasks,
    List<DateTime>? addDates,
    List<DateTime>? removeDates,
    List<int>? addInts,
    List<int>? removeInts,
    int? incrementInteger,
    double? incrementDoub,
    int? decrementInteger,
    double? decrementDoub,
    bool deleteSubtasks = false,
    bool deleteDates = false,
    bool deleteInts = false,
    bool deleteInteger = false,
    bool deleteDoub = false,
    bool deleteStr = false,
    bool deleteSubtask = false,
    bool deleteDate = false,
  }) => updateSelfRaw<Task>({
    if (integer != null) 'integer': integer,
    if (doub != null) 'doub': doub,
    if (str != null) 'str': str,
    if (subtask != null) 'subtask': subtask.toMap(),
    if (date != null) 'date': date.toIso8601String(),
    if (addSubtasks != null && addSubtasks.isNotEmpty)
      'subtasks': FieldValue.arrayUnion(
        addSubtasks.map((v) => v.toMap()).toList(),
      ),
    if (removeSubtasks != null && removeSubtasks.isNotEmpty)
      'subtasks': FieldValue.arrayRemove(
        removeSubtasks.map((v) => v.toMap()).toList(),
      ),
    if (addDates != null && addDates.isNotEmpty)
      'dates': FieldValue.arrayUnion(
        addDates.map((v) => v.toIso8601String()).toList(),
      ),
    if (removeDates != null && removeDates.isNotEmpty)
      'dates': FieldValue.arrayRemove(
        removeDates.map((v) => v.toIso8601String()).toList(),
      ),
    if (addInts != null && addInts.isNotEmpty)
      'ints': FieldValue.arrayUnion(addInts.map((v) => v).toList()),
    if (removeInts != null && removeInts.isNotEmpty)
      'ints': FieldValue.arrayRemove(removeInts.map((v) => v).toList()),
    if (incrementInteger != null)
      'integer': FieldValue.increment(incrementInteger),
    if (incrementDoub != null) 'doub': FieldValue.increment(incrementDoub),
    if (decrementInteger != null)
      'integer': FieldValue.decrement(decrementInteger),
    if (decrementDoub != null) 'doub': FieldValue.decrement(decrementDoub),
    if (deleteSubtasks) 'subtasks': FieldValue.delete(),
    if (deleteDates) 'dates': FieldValue.delete(),
    if (deleteInts) 'ints': FieldValue.delete(),
    if (deleteInteger) 'integer': FieldValue.delete(),
    if (deleteDoub) 'doub': FieldValue.delete(),
    if (deleteStr) 'str': FieldValue.delete(),
    if (deleteSubtask) 'subtask': FieldValue.delete(),
    if (deleteDate) 'date': FieldValue.delete(),
  });
}

/// CRUD Extensions for Task.Subtask
extension XFCrud$Task$Subtask on Task {
  Future<List<Subtask>> getSubtasks([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => getAll<Subtask>(query);
  Stream<List<Subtask>> streamSubtasks([
    CollectionReference Function(CollectionReference ref)? query,
  ]) => streamAll<Subtask>(query);
  Future<void> setSubtask(String id, Subtask value) => set<Subtask>(id, value);
  Future<void> updateSubtask(String id, Map<String, dynamic> updates) =>
      update<Subtask>(id, updates);
  Stream<Subtask?> streamSubtask(String id) => stream<Subtask>(id);
  Future<void> deleteSubtask(String id) => delete<Subtask>(id);
  Future<void> addSubtask(Subtask value) => add<Subtask>(value);
  Future<void> setSubtaskAtomic(String id, Subtask Function(Subtask?) txn) =>
      setAtomic<Subtask>(id, txn);
  Future<void> ensureSubtaskExists(String id, Subtask or) =>
      ensureExists<Subtask>(id, or);
  Subtask subtaskModel(String id) => model<Subtask>();
}
