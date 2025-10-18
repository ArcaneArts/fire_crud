import 'package:artifact/artifact.dart';
import 'package:example/subtask.dart';
import 'package:fire_crud/fire_crud.dart';

@artifact
class Task with ModelCrud {
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
    FireModel<Subtask>.artifact("subtask"),
  ];
}
