library fire_crud;

import 'package:fire_crud/src/model_crud.dart';

export 'package:fire_crud/src/child_model.dart';
export 'package:fire_crud/src/collection_view.dart';
export 'package:fire_crud/src/fire_crud.dart';
export 'package:fire_crud/src/model_accessor.dart';
export 'package:fire_crud/src/model_crud.dart';
export 'package:fire_crud/src/model_utility.dart';

enum ModelCodec {
  jsonMappable,
}

class Model<T extends ModelCrud> {
  final String collection;
  final ModelCodec codec;

  const Model({required this.collection, this.codec = ModelCodec.jsonMappable});
}

class ExclusiveModel<T extends ModelCrud> extends Model<T> {
  final String exclusiveDocumentId;

  const ExclusiveModel({
    required super.collection,
    required this.exclusiveDocumentId,
  });
}

class FireCrudGenerator<T extends ModelCrud> {
  final List<Model> children;

  const FireCrudGenerator({
    this.children = const [],
  });
}
