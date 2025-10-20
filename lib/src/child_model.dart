import 'package:fire_crud/fire_crud.dart';
import 'package:pylon_codec/pylon_codec.dart';

Map<Type, int> _rc = {};

Map<String, dynamic> Function(Object o)? _fcaToMap;
T Function<T>(Map<String, dynamic> m)? _fcaFromMap;
T Function<T>()? _fcaConstruct;

void $registerFCA(
  T Function<T>(Map<String, dynamic> m) artifactFromMap,
  Map<String, dynamic> Function(Object o) artifactToMap,
  T Function<T>() artifactConstruct,
) {
  _fcaToMap = artifactToMap;
  _fcaFromMap = artifactFromMap;
  _fcaConstruct = artifactConstruct;
}

void _checkFCA() {
  if (_fcaFromMap == null || _fcaToMap == null) {
    throw Exception(
        "FireCrud is trying to use artifact, please call `\$crud.setupArtifact(\$artifactFromMap, \$artifactToMap, \$constructArtifact);` during initialization.");
  }
}

/// Represents a child model that can be nested within a parent model in the fire_crud package.
/// This class provides type information for [ModelCrud] instances and defines how to serialize
/// to and deserialize from maps, enabling proper handling of hierarchical data structures in Firestore.
/// Specify the generic type T (extending [ModelCrud]) explicitly for correct functionality.
class FireModel<T extends ModelCrud> {
  /// The subcollection name that this child model belongs to within its parent document.
  final String collection;

  /// The document ID of the parent if this child model is exclusive to a specific document;
  /// otherwise, null for models that can appear in multiple documents.
  final String? exclusiveDocumentId;

  /// The parent model instance that this child model is associated with.
  /// T must extend [ModelCrud] to ensure compatibility with CRUD operations.
  final T model;

  /// Function to serialize the model instance to a [Map]<[String], [dynamic]> for storage or transmission.
  final Map<String, dynamic> Function(T crud) toMap;

  /// Function to deserialize a [Map]<[String], [dynamic]> into a model instance of type T.
  final T Function(Map<String, dynamic>) fromMap;

  /// Late-initialized template path for generating document paths for this child model.
  late String templatePath;

  /// Returns the parent template path by removing the last two path segments from [templatePath].
  /// This is used to derive the path to the containing parent document.
  String get parentTemplatePath => _parentPath(templatePath);

  /// Clones the current model instance with a new document path.
  /// Optionally uses a different model instance for cloning; defaults to the current [model].
  /// Returns a new instance of T with the updated path set via [ModelCrud.documentPath].
  T cloneWithPath(String path, [T? useModel]) =>
      fromMap(toMap(useModel ?? model))..documentPath = path;

  /// Creates a new model instance from the provided data map with the specified document path.
  /// Returns null if the data is null; otherwise, deserializes the data and sets the path.
  T? withPath(Map<String, dynamic>? data, String path) =>
      data == null ? null : (fromMap(data)..documentPath = path);

  /// Creates a new [FireModel] instance with the required collection, model, and serialization functions.
  /// Initializes the child model configuration for use in nested Firestore operations.
  FireModel(
      {required this.collection,
      required this.model,
      required this.toMap,
      required this.fromMap,
      this.exclusiveDocumentId});

  /// Factory constructor for creating a [FireModel] using registered artifact functions.
  /// Retrieves serialization and construction functions from global registry after checking availability.
  /// Intended for use with pre-registered artifacts in the fire_crud setup.
  factory FireModel.artifact(String collectionName,
      {String? exclusiveDocumentId}) {
    _checkFCA();
    return FireModel<T>(
        collection: collectionName,
        exclusiveDocumentId: exclusiveDocumentId,
        model: _fcaConstruct!<T>(),
        toMap: _fcaToMap!,
        fromMap: _fcaFromMap!);
  }

  /// Registers the model type with the [FireCrud] instance and recursively registers child models.
  /// Sets up template paths for document generation and tracks registration count to prevent excess calls (limited to 10 per type).
  /// Integrates with Pylon codec for serialization support.
  void registerTypeModels() {
    if ((_rc[model.runtimeType] ?? 0) > 10) {
      return;
    }

    _rc[model.runtimeType] = (_rc[model.runtimeType] ?? 0) + 1;

    registerPylonCodec(model);

    for (FireModel i in model.childModels) {
      FireCrud.instance().typeModels[i.model.runtimeType] = i;
      i.templatePath =
          "$templatePath/${"${i.collection}/\$${i.model.runtimeType}.id"}";
      i.registerTypeModels();
    }
  }
}

String _parentPath(String path) {
  List<String> s = path.split("/");
  s.removeLast();
  s.removeLast();
  return s.join("/");
}
