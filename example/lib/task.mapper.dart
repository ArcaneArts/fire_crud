// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, unnecessary_cast, override_on_non_overriding_member
// ignore_for_file: strict_raw_type, inference_failure_on_untyped_parameter

part of 'task.dart';

class TaskMapper extends ClassMapperBase<Task> {
  TaskMapper._();

  static TaskMapper? _instance;
  static TaskMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = TaskMapper._());
      SubtaskMapper.ensureInitialized();
    }
    return _instance!;
  }

  @override
  final String id = 'Task';

  static List<DateTime> _$dates(Task v) => v.dates;
  static const Field<Task, List<DateTime>> _f$dates =
      Field('dates', _$dates, opt: true, def: const []);
  static List<Subtask> _$subtasks(Task v) => v.subtasks;
  static const Field<Task, List<Subtask>> _f$subtasks =
      Field('subtasks', _$subtasks, opt: true, def: const []);
  static List<int> _$ints(Task v) => v.ints;
  static const Field<Task, List<int>> _f$ints =
      Field('ints', _$ints, opt: true, def: const []);
  static int _$integer(Task v) => v.integer;
  static const Field<Task, int> _f$integer =
      Field('integer', _$integer, opt: true, def: 0);
  static double _$doub(Task v) => v.doub;
  static const Field<Task, double> _f$doub =
      Field('doub', _$doub, opt: true, def: 0);
  static Subtask? _$subtask(Task v) => v.subtask;
  static const Field<Task, Subtask> _f$subtask =
      Field('subtask', _$subtask, opt: true);
  static DateTime? _$date(Task v) => v.date;
  static const Field<Task, DateTime> _f$date = Field('date', _$date, opt: true);
  static String _$str(Task v) => v.str;
  static const Field<Task, String> _f$str =
      Field('str', _$str, opt: true, def: "");

  @override
  final MappableFields<Task> fields = const {
    #dates: _f$dates,
    #subtasks: _f$subtasks,
    #ints: _f$ints,
    #integer: _f$integer,
    #doub: _f$doub,
    #subtask: _f$subtask,
    #date: _f$date,
    #str: _f$str,
  };

  static Task _instantiate(DecodingData data) {
    return Task(
        dates: data.dec(_f$dates),
        subtasks: data.dec(_f$subtasks),
        ints: data.dec(_f$ints),
        integer: data.dec(_f$integer),
        doub: data.dec(_f$doub),
        subtask: data.dec(_f$subtask),
        date: data.dec(_f$date),
        str: data.dec(_f$str));
  }

  @override
  final Function instantiate = _instantiate;

  static Task fromMap(Map<String, dynamic> map) {
    return ensureInitialized().decodeMap<Task>(map);
  }

  static Task fromJson(String json) {
    return ensureInitialized().decodeJson<Task>(json);
  }
}

mixin TaskMappable {
  String toJson() {
    return TaskMapper.ensureInitialized().encodeJson<Task>(this as Task);
  }

  Map<String, dynamic> toMap() {
    return TaskMapper.ensureInitialized().encodeMap<Task>(this as Task);
  }

  TaskCopyWith<Task, Task, Task> get copyWith =>
      _TaskCopyWithImpl<Task, Task>(this as Task, $identity, $identity);
  @override
  String toString() {
    return TaskMapper.ensureInitialized().stringifyValue(this as Task);
  }

  @override
  bool operator ==(Object other) {
    return TaskMapper.ensureInitialized().equalsValue(this as Task, other);
  }

  @override
  int get hashCode {
    return TaskMapper.ensureInitialized().hashValue(this as Task);
  }
}

extension TaskValueCopy<$R, $Out> on ObjectCopyWith<$R, Task, $Out> {
  TaskCopyWith<$R, Task, $Out> get $asTask =>
      $base.as((v, t, t2) => _TaskCopyWithImpl<$R, $Out>(v, t, t2));
}

abstract class TaskCopyWith<$R, $In extends Task, $Out>
    implements ClassCopyWith<$R, $In, $Out> {
  ListCopyWith<$R, DateTime, ObjectCopyWith<$R, DateTime, DateTime>> get dates;
  ListCopyWith<$R, Subtask, SubtaskCopyWith<$R, Subtask, Subtask>> get subtasks;
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>> get ints;
  SubtaskCopyWith<$R, Subtask, Subtask>? get subtask;
  $R call(
      {List<DateTime>? dates,
      List<Subtask>? subtasks,
      List<int>? ints,
      int? integer,
      double? doub,
      Subtask? subtask,
      DateTime? date,
      String? str});
  TaskCopyWith<$R2, $In, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t);
}

class _TaskCopyWithImpl<$R, $Out> extends ClassCopyWithBase<$R, Task, $Out>
    implements TaskCopyWith<$R, Task, $Out> {
  _TaskCopyWithImpl(super.value, super.then, super.then2);

  @override
  late final ClassMapperBase<Task> $mapper = TaskMapper.ensureInitialized();
  @override
  ListCopyWith<$R, DateTime, ObjectCopyWith<$R, DateTime, DateTime>>
      get dates => ListCopyWith($value.dates,
          (v, t) => ObjectCopyWith(v, $identity, t), (v) => call(dates: v));
  @override
  ListCopyWith<$R, Subtask, SubtaskCopyWith<$R, Subtask, Subtask>>
      get subtasks => ListCopyWith($value.subtasks,
          (v, t) => v.copyWith.$chain(t), (v) => call(subtasks: v));
  @override
  ListCopyWith<$R, int, ObjectCopyWith<$R, int, int>> get ints => ListCopyWith(
      $value.ints,
      (v, t) => ObjectCopyWith(v, $identity, t),
      (v) => call(ints: v));
  @override
  SubtaskCopyWith<$R, Subtask, Subtask>? get subtask =>
      $value.subtask?.copyWith.$chain((v) => call(subtask: v));
  @override
  $R call(
          {List<DateTime>? dates,
          List<Subtask>? subtasks,
          List<int>? ints,
          int? integer,
          double? doub,
          Object? subtask = $none,
          Object? date = $none,
          String? str}) =>
      $apply(FieldCopyWithData({
        if (dates != null) #dates: dates,
        if (subtasks != null) #subtasks: subtasks,
        if (ints != null) #ints: ints,
        if (integer != null) #integer: integer,
        if (doub != null) #doub: doub,
        if (subtask != $none) #subtask: subtask,
        if (date != $none) #date: date,
        if (str != null) #str: str
      }));
  @override
  Task $make(CopyWithData data) => Task(
      dates: data.get(#dates, or: $value.dates),
      subtasks: data.get(#subtasks, or: $value.subtasks),
      ints: data.get(#ints, or: $value.ints),
      integer: data.get(#integer, or: $value.integer),
      doub: data.get(#doub, or: $value.doub),
      subtask: data.get(#subtask, or: $value.subtask),
      date: data.get(#date, or: $value.date),
      str: data.get(#str, or: $value.str));

  @override
  TaskCopyWith<$R2, Task, $Out2> $chain<$R2, $Out2>(Then<$Out2, $R2> t) =>
      _TaskCopyWithImpl<$R2, $Out2>($value, $cast, t);
}
