import 'package:example/gen/artifacts.gen.dart';
import 'package:example/gen/crud.gen.dart';
import 'package:example/task.dart';
import 'package:fire_crud/fire_crud.dart';

enum En { a, b, c }

void main() {
  registerFCA($artifactFromMap, $artifactToMap, $constructArtifact);

  $crud.registerModel(FireModel<Task>.artifact("task"));

  print($crud.taskModel("derp").documentPath);
}
