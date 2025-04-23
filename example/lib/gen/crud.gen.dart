// GENERATED – do not modify.
import "dart:core";

import "package:example/en.dart";
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

  Future<void> modify({
    /// Adds multiple [Subtask] to the [subtasks] field atomically using FieldValue.arrayUnion(). See https://cloud.google.com/firestore/docs/manage-data/add-data#update_elements_in_an_array
    List<Subtask>? addSubtasks,

    /// Removes one or more [Subtask] to the [subtasks] field atomically using FieldValue.arrayRemove(). See https://cloud.google.com/firestore/docs/manage-data/add-data#update_elements_in_an_array
    List<Subtask>? removeSubtasks,

    /// Replaces the value of [subtasks] with a new value atomically.
    List<Subtask>? subtasks,

    /// Removes the [subtasks] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteSubtasks = false,

    /// Adds multiple [DateTime] to the [dates] field atomically using FieldValue.arrayUnion(). See https://cloud.google.com/firestore/docs/manage-data/add-data#update_elements_in_an_array
    List<DateTime>? addDates,

    /// Removes one or more [DateTime] to the [dates] field atomically using FieldValue.arrayRemove(). See https://cloud.google.com/firestore/docs/manage-data/add-data#update_elements_in_an_array
    List<DateTime>? removeDates,

    /// Replaces the value of [dates] with a new value atomically.
    List<DateTime>? dates,

    /// Removes the [dates] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDates = false,

    /// Adds multiple [int] to the [ints] field atomically using FieldValue.arrayUnion(). See https://cloud.google.com/firestore/docs/manage-data/add-data#update_elements_in_an_array
    List<int>? addInts,

    /// Removes one or more [int] to the [ints] field atomically using FieldValue.arrayRemove(). See https://cloud.google.com/firestore/docs/manage-data/add-data#update_elements_in_an_array
    List<int>? removeInts,

    /// Replaces the value of [ints] with a new value atomically.
    List<int>? ints,

    /// Removes the [ints] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteInts = false,

    /// Changes (increment/decrement) [integer] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaInteger,

    /// Replaces the value of [integer] with a new value atomically.
    int? integer,

    /// Removes the [integer] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteInteger = false,

    /// Changes (increment/decrement) [doub] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    double? deltaDoub,

    /// Replaces the value of [doub] with a new value atomically.
    double? doub,

    /// Removes the [doub] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDoub = false,

    /// Replaces the value of [str] with a new value atomically.
    String? str,

    /// Removes the [str] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteStr = false,

    /// Replaces the value of [subtask] with a new value atomically.
    Subtask? subtask,

    /// Removes the [subtask] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteSubtask = false,

    /// Replaces the value of [date] with a new value atomically.
    DateTime? date,

    /// Removes the [date] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDate = false,
    bool $z = false,
  }) => updateSelfRaw<Task>({
    if (addSubtasks != null && addSubtasks.isNotEmpty)
      'subtasks': FieldValue.arrayUnion(
        addSubtasks.map((v) => v.toMap()).toList(),
      ),
    if (removeSubtasks != null && removeSubtasks.isNotEmpty)
      'subtasks': FieldValue.arrayRemove(
        removeSubtasks.map((v) => v.toMap()).toList(),
      ),
    if (deleteSubtasks) 'subtasks': FieldValue.delete(),
    if (addDates != null && addDates.isNotEmpty)
      'dates': FieldValue.arrayUnion(
        addDates.map((v) => v.toIso8601String()).toList(),
      ),
    if (removeDates != null && removeDates.isNotEmpty)
      'dates': FieldValue.arrayRemove(
        removeDates.map((v) => v.toIso8601String()).toList(),
      ),
    if (deleteDates) 'dates': FieldValue.delete(),
    if (addInts != null && addInts.isNotEmpty)
      'ints': FieldValue.arrayUnion(addInts.map((v) => v).toList()),
    if (removeInts != null && removeInts.isNotEmpty)
      'ints': FieldValue.arrayRemove(removeInts.map((v) => v).toList()),
    if (deleteInts) 'ints': FieldValue.delete(),
    if (integer != null) 'integer': integer,
    if (deltaInteger != null) 'integer': FieldValue.increment(deltaInteger),
    if (deleteInteger) 'integer': FieldValue.delete(),
    if (doub != null) 'doub': doub,
    if (deltaDoub != null) 'doub': FieldValue.increment(deltaDoub),
    if (deleteDoub) 'doub': FieldValue.delete(),
    if (str != null) 'str': str,
    if (deleteStr) 'str': FieldValue.delete(),
    if (subtask != null) 'subtask': subtask.toMap(),
    if (deleteSubtask) 'subtask': FieldValue.delete(),
    if (date != null) 'date': date.toIso8601String(),
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
  Future<void> setSubtask(String id, Subtask value) => $set<Subtask>(id, value);
  Future<Subtask?> getSubtask(String id) => $get<Subtask>(id);
  Future<void> updateSubtask(String id, Map<String, dynamic> updates) =>
      $update<Subtask>(id, updates);
  Stream<Subtask?> streamSubtask(String id) => $stream<Subtask>(id);
  Future<void> deleteSubtask(String id) => $delete<Subtask>(id);
  Future<Subtask> addSubtask(Subtask value) => $add<Subtask>(value);
  Future<void> setSubtaskAtomic(String id, Subtask Function(Subtask?) txn) =>
      $setAtomic<Subtask>(id, txn);
  Future<void> ensureSubtaskExists(String id, Subtask or) =>
      $ensureExists<Subtask>(id, or);
  Subtask subtaskModel(String id) => $model<Subtask>();
  Future<void> modifySubtask({
    required String id,

    /// Replaces the value of [title] with a new value atomically.
    String? title,

    /// Removes the [title] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteTitle = false,

    /// Changes (increment/decrement) [a] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaA,

    /// Replaces the value of [a] with a new value atomically.
    int? a,

    /// Removes the [a] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteA = false,

    /// Changes (increment/decrement) [b] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaB,

    /// Replaces the value of [b] with a new value atomically.
    int? b,

    /// Removes the [b] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteB = false,

    /// Changes (increment/decrement) [c] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    double? deltaC,

    /// Replaces the value of [c] with a new value atomically.
    double? c,

    /// Removes the [c] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteC = false,

    /// Changes (increment/decrement) [d] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    double? deltaD,

    /// Replaces the value of [d] with a new value atomically.
    double? d,

    /// Removes the [d] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteD = false,

    /// Replaces the value of [dt] with a new value atomically.
    DateTime? dt,

    /// Removes the [dt] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDt = false,

    /// Replaces the value of [en] with a new value atomically.
    En? en,

    /// Removes the [en] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteEn = false,
    bool $z = false,
  }) => $update<Subtask>(id, {
    if (title != null) 'title': title,
    if (deleteTitle) 'title': FieldValue.delete(),
    if (a != null) 'a': a,
    if (deltaA != null) 'a': FieldValue.increment(deltaA),
    if (deleteA) 'a': FieldValue.delete(),
    if (b != null) 'b': b,
    if (deltaB != null) 'b': FieldValue.increment(deltaB),
    if (deleteB) 'b': FieldValue.delete(),
    if (c != null) 'c': c,
    if (deltaC != null) 'c': FieldValue.increment(deltaC),
    if (deleteC) 'c': FieldValue.delete(),
    if (d != null) 'd': d,
    if (deltaD != null) 'd': FieldValue.increment(deltaD),
    if (deleteD) 'd': FieldValue.delete(),
    if (dt != null) 'dt': dt.toIso8601String(),
    if (deleteDt) 'dt': FieldValue.delete(),
    if (en != null) 'en': en.name,
    if (deleteEn) 'en': FieldValue.delete(),
  });
}

/// CRUD Extensions for Subtask
extension XFCrudBase$Subtask on Subtask {
  /// Gets this document (self) live and returns a new instance of [Subtask] representing the new data
  Future<Subtask?> get() => getSelfRaw<Subtask>();

  /// Opens a self stream of [Subtask] representing this document
  Stream<Subtask?> stream() => streamSelfRaw<Subtask>();

  /// Sets this [Subtask] document to a new value
  Future<void> set(Subtask to) => setSelfRaw<Subtask>(to);

  /// Updates properties of this [Subtask] with {"fieldName": VALUE, ...}
  Future<void> update(Map<String, dynamic> u) => updateSelfRaw<Subtask>(u);

  /// Deletes this [Subtask] document
  Future<void> delete() => deleteSelfRaw<Subtask>();

  /// Sets this [Subtask] document atomically by getting first then setting.
  Future<void> setAtomic(Subtask Function(Subtask?) txn) =>
      setSelfAtomicRaw<Subtask>(txn);

  Future<void> modify({
    /// Replaces the value of [title] with a new value atomically.
    String? title,

    /// Removes the [title] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteTitle = false,

    /// Changes (increment/decrement) [a] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaA,

    /// Replaces the value of [a] with a new value atomically.
    int? a,

    /// Removes the [a] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteA = false,

    /// Changes (increment/decrement) [b] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? deltaB,

    /// Replaces the value of [b] with a new value atomically.
    int? b,

    /// Removes the [b] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteB = false,

    /// Changes (increment/decrement) [c] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    double? deltaC,

    /// Replaces the value of [c] with a new value atomically.
    double? c,

    /// Removes the [c] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteC = false,

    /// Changes (increment/decrement) [d] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    double? deltaD,

    /// Replaces the value of [d] with a new value atomically.
    double? d,

    /// Removes the [d] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteD = false,

    /// Replaces the value of [dt] with a new value atomically.
    DateTime? dt,

    /// Removes the [dt] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteDt = false,

    /// Replaces the value of [en] with a new value atomically.
    En? en,

    /// Removes the [en] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteEn = false,
    bool $z = false,
  }) => updateSelfRaw<Subtask>({
    if (title != null) 'title': title,
    if (deleteTitle) 'title': FieldValue.delete(),
    if (a != null) 'a': a,
    if (deltaA != null) 'a': FieldValue.increment(deltaA),
    if (deleteA) 'a': FieldValue.delete(),
    if (b != null) 'b': b,
    if (deltaB != null) 'b': FieldValue.increment(deltaB),
    if (deleteB) 'b': FieldValue.delete(),
    if (c != null) 'c': c,
    if (deltaC != null) 'c': FieldValue.increment(deltaC),
    if (deleteC) 'c': FieldValue.delete(),
    if (d != null) 'd': d,
    if (deltaD != null) 'd': FieldValue.increment(deltaD),
    if (deleteD) 'd': FieldValue.delete(),
    if (dt != null) 'dt': dt.toIso8601String(),
    if (deleteDt) 'dt': FieldValue.delete(),
    if (en != null) 'en': en.name,
    if (deleteEn) 'en': FieldValue.delete(),
  });
}
