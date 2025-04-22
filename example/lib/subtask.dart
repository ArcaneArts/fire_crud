import 'package:dart_mappable/dart_mappable.dart';
import 'package:example/en.dart';
import 'package:fire_crud/fire_crud.dart';

part 'subtask.mapper.dart';

@MappableClass()
class Subtask with SubtaskMappable, ModelCrud {
  final String? title;
  final int? a;
  final int b;
  final double? c;
  final double d;
  final DateTime dt;
  final En? en;

  Subtask({
    this.title,
    this.b = 0,
    this.c,
    this.d = 0,
    this.a,
    required this.dt,
    this.en,
  });

  @override
  List<FireModel<ModelCrud>> get childModels => [];
}
