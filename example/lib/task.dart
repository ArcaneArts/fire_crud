import 'package:dart_mappable/dart_mappable.dart';
import 'package:example/subtask.dart';
import 'package:fire_crud/fire_crud.dart';

part 'task.mapper.dart';

@MappableClass()
class Task with TaskMappable, ModelCrud {
  final List<Subtask> subtasks;
  final List<DateTime> dates;
  final List<int> ints;
  final int integer;
  final double doub;
  final String str;
  final Subtask? subtask;
  final DateTime? date;

  Task({
    this.dates = const [],
    this.subtasks = const [],
    this.ints = const [],
    this.integer = 0,
    this.doub = 0,
    this.subtask,
    this.date,
    this.str = "",
  });

  @override
  List<FireModel<ModelCrud>> get childModels => [
    FireModel<Subtask>(
      collection: "subtask",
      toMap: (m) => m.toMap(),
      fromMap: (m) => SubtaskMapper.fromMap(m),
      model: Subtask(dt: DateTime.timestamp()),
    ),
  ];
}
