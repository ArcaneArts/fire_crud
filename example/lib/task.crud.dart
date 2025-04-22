// GENERATED – do not modify.
import 'package:example/task.dart';
import 'package:example/subtask.dart';
import "dart:core";
import 'dart:core';
import "package:example/subtask.dart";
import 'package:fire_api/fire_api.dart';
import 'package:example/subtask.dart';
import "dart:core";
import "package:example/en.dart";

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
  Future<void> setAtomic(Task Function(Task?) txn) => setSelfAtomicRaw<Task>(txn);
  
  Future<void> mutate({
    
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
    
    /// Increases [integer] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? incrementInteger,
    
    /// Reduces [integer] by an amount atomically using FieldValue.decrement() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? decrementInteger,
    
    /// Replaces the value of [integer] with a new value atomically.
    int? integer,
    
    /// Removes the [integer] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteInteger = false,
    
    /// Increases [doub] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    double? incrementDoub,
    
    /// Reduces [doub] by an amount atomically using FieldValue.decrement() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    double? decrementDoub,
    
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
    bool deleteDate = false
  }) =>
    updateSelfRaw<Task>({ 
      if(addSubtasks != null && addSubtasks.isNotEmpty) 'subtasks': FieldValue.arrayUnion(addSubtasks.map((v) => v.toMap()).toList()),
      if(removeSubtasks != null && removeSubtasks.isNotEmpty) 'subtasks': FieldValue.arrayRemove(removeSubtasks.map((v) => v.toMap()).toList()),
      if(deleteSubtasks) 'subtasks': FieldValue.delete(),
      if(addDates != null && addDates.isNotEmpty) 'dates': FieldValue.arrayUnion(addDates.map((v) => v.toIso8601String()).toList()),
      if(removeDates != null && removeDates.isNotEmpty) 'dates': FieldValue.arrayRemove(removeDates.map((v) => v.toIso8601String()).toList()),
      if(deleteDates) 'dates': FieldValue.delete(),
      if(addInts != null && addInts.isNotEmpty) 'ints': FieldValue.arrayUnion(addInts.map((v) => v).toList()),
      if(removeInts != null && removeInts.isNotEmpty) 'ints': FieldValue.arrayRemove(removeInts.map((v) => v).toList()),
      if(deleteInts) 'ints': FieldValue.delete(),
      if(integer != null) 'integer': integer,
      if(incrementInteger != null) 'integer': FieldValue.increment(incrementInteger),
      if(decrementInteger != null) 'integer': FieldValue.decrement(decrementInteger),
      if(deleteInteger) 'integer': FieldValue.delete(),
      if(doub != null) 'doub': doub,
      if(incrementDoub != null) 'doub': FieldValue.increment(incrementDoub),
      if(decrementDoub != null) 'doub': FieldValue.decrement(decrementDoub),
      if(deleteDoub) 'doub': FieldValue.delete(),
      if(str != null) 'str': str,
      if(deleteStr) 'str': FieldValue.delete(),
      if(subtask != null) 'subtask': subtask.toMap(),
      if(deleteSubtask) 'subtask': FieldValue.delete(),
      if(date != null) 'date': date.toIso8601String(),
      if(deleteDate) 'date': FieldValue.delete()
    });
}
    
/// CRUD Extensions for Task.Subtask
extension XFCrud$Task$Subtask on Task {
  Future<List<Subtask>> getSubtasks([CollectionReference Function(CollectionReference ref)? query]) => getAll<Subtask>(query);
  Stream<List<Subtask>> streamSubtasks([CollectionReference Function(CollectionReference ref)? query]) => streamAll<Subtask>(query);
  Future<void> setSubtask(String id, Subtask value) => $set<Subtask>(id, value);
  Future<void> updateSubtask(String id, Map<String, dynamic> updates) => $update<Subtask>(id, updates);
  Stream<Subtask?> streamSubtask(String id) => $stream<Subtask>(id);
  Future<void> deleteSubtask(String id) => $delete<Subtask>(id);
  Future<void> addSubtask(Subtask value) => $add<Subtask>(value);
  Future<void> setSubtaskAtomic(String id, Subtask Function(Subtask?) txn) => $setAtomic<Subtask>(id, txn);
  Future<void> ensureSubtaskExists(String id, Subtask or) => $ensureExists<Subtask>(id, or);
  Subtask subtaskModel(String id) => $model<Subtask>();
  Future<void> mutateSubtask({
    required String id,
    
    /// Replaces the value of [title] with a new value atomically.
    String? title,
    
    /// Removes the [title] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteTitle = false,
    
    /// Increases [a] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? incrementA,
    
    /// Reduces [a] by an amount atomically using FieldValue.decrement() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? decrementA,
    
    /// Replaces the value of [a] with a new value atomically.
    int? a,
    
    /// Removes the [a] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteA = false,
    
    /// Increases [b] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? incrementB,
    
    /// Reduces [b] by an amount atomically using FieldValue.decrement() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    int? decrementB,
    
    /// Replaces the value of [b] with a new value atomically.
    int? b,
    
    /// Removes the [b] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteB = false,
    
    /// Increases [c] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    double? incrementC,
    
    /// Reduces [c] by an amount atomically using FieldValue.decrement() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    double? decrementC,
    
    /// Replaces the value of [c] with a new value atomically.
    double? c,
    
    /// Removes the [c] field from the document atomically using FieldValue.delete(). See https://cloud.google.com/firestore/docs/manage-data/delete-data#fields
    bool deleteC = false,
    
    /// Increases [d] by an amount atomically using FieldValue.increment() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    double? incrementD,
    
    /// Reduces [d] by an amount atomically using FieldValue.decrement() see https://cloud.google.com/firestore/docs/manage-data/add-data#increment_a_numeric_value.
    double? decrementD,
    
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
    bool deleteEn = false
  }) =>
    $update<Subtask>(id, { 
      if(title != null) 'title': title,
      if(deleteTitle) 'title': FieldValue.delete(),
      if(a != null) 'a': a,
      if(incrementA != null) 'a': FieldValue.increment(incrementA),
      if(decrementA != null) 'a': FieldValue.decrement(decrementA),
      if(deleteA) 'a': FieldValue.delete(),
      if(b != null) 'b': b,
      if(incrementB != null) 'b': FieldValue.increment(incrementB),
      if(decrementB != null) 'b': FieldValue.decrement(decrementB),
      if(deleteB) 'b': FieldValue.delete(),
      if(c != null) 'c': c,
      if(incrementC != null) 'c': FieldValue.increment(incrementC),
      if(decrementC != null) 'c': FieldValue.decrement(decrementC),
      if(deleteC) 'c': FieldValue.delete(),
      if(d != null) 'd': d,
      if(incrementD != null) 'd': FieldValue.increment(incrementD),
      if(decrementD != null) 'd': FieldValue.decrement(decrementD),
      if(deleteD) 'd': FieldValue.delete(),
      if(dt != null) 'dt': dt.toIso8601String(),
      if(deleteDt) 'dt': FieldValue.delete(),
      if(en != null) 'en': en.name,
      if(deleteEn) 'en': FieldValue.delete()
    });
}

