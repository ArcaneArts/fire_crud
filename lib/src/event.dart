import 'package:fire_crud/fire_crud.dart';

class FireCrudEvent {
  final int reads;
  final int writes;
  final int deletes;

  FireCrudEvent({this.reads = 0, this.writes = 0, this.deletes = 0});

  FireCrudEvent operator +(FireCrudEvent other) => FireCrudEvent(
        reads: reads + other.reads,
        writes: writes + other.writes,
        deletes: deletes + other.deletes,
      );

  double get cost =>
      (reads * kFireCrudCostPerRead) +
      (writes * kFireCrudCostPerWrite) +
      (deletes * kFireCrudCostPerDelete);
}
