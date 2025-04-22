// GENERATED – do not modify.
import 'package:example/subtask.dart';
import "dart:core";
import "package:example/en.dart";
import 'package:fire_api/fire_api.dart';

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
  Future<void> setAtomic(Subtask Function(Subtask?) txn) => setSelfAtomicRaw<Subtask>(txn);
  
  Future<void> mutate({
    
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
    updateSelfRaw<Subtask>({ 
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
    
