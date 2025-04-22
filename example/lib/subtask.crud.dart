// GENERATED – do not modify.
import 'package:example/subtask.dart';
import 'dart:core';
import 'package:example/en.dart';
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
  
  Future<void> mutate({String? title, int? a, int? b, double? c, double? d, DateTime? dt, En? en, int? incrementA, int? incrementB, double? incrementC, double? incrementD, int? decrementA, int? decrementB, double? decrementC, double? decrementD, bool deleteTitle = false, bool deleteA = false, bool deleteB = false, bool deleteC = false, bool deleteD = false, bool deleteDt = false, bool deleteEn = false}) =>
    updateSelfRaw<Subtask>({ 
      if(title != null) 'title': title,
if(a != null) 'a': a,
if(b != null) 'b': b,
if(c != null) 'c': c,
if(d != null) 'd': d,
if(dt != null) 'dt': dt.toIso8601String(),
if(en != null) 'en': en.name,
if(incrementA != null) 'a': FieldValue.increment(incrementA),
if(incrementB != null) 'b': FieldValue.increment(incrementB),
if(incrementC != null) 'c': FieldValue.increment(incrementC),
if(incrementD != null) 'd': FieldValue.increment(incrementD),
if(decrementA != null) 'a': FieldValue.decrement(decrementA),
if(decrementB != null) 'b': FieldValue.decrement(decrementB),
if(decrementC != null) 'c': FieldValue.decrement(decrementC),
if(decrementD != null) 'd': FieldValue.decrement(decrementD),
if(deleteTitle) 'title': FieldValue.delete(),
if(deleteA) 'a': FieldValue.delete(),
if(deleteB) 'b': FieldValue.delete(),
if(deleteC) 'c': FieldValue.delete(),
if(deleteD) 'd': FieldValue.delete(),
if(deleteDt) 'dt': FieldValue.delete(),
if(deleteEn) 'en': FieldValue.delete()
    });
}
    
