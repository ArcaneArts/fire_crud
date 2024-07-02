library fire_crud;

void whatIWant() {
  // Basic setting update
  User user = FireCrud.pull<User>("dan");
  UserSettings settings = user.pullSingleton<UserSettings>();

  // Update a setting
  user.push<UserSettings>(settings.mutate(dark: true));

  // Push atomically (doesnt need to pull first, but is slower but very safe)
  user.pushAtomic<UserSettings>((s) => s.mutate(dark: true));

  // Stream Settings
  Stream<UserSettings> settingsStream = user.stream<UserSettings>();

  // Get all guides in a library
  Library library = FireCrud.pull<Library>("library");
  List<Guide> guides = library.pullAll<Guide>();

  // Stream all
  Stream<List<Guide>> guideStream = library.streamAll<Guide>();

  // Get a single guide
  Guide guide = library.pull<Guide>("guideId");

  // Add a guide
  library.add<Guide>(Guide(title: "New Guide"));

  // Deeply update a guide without pulling anything
  FireCrud.model<Library>("libraryId")
      .pushAtomic<Guide>("guideId", (g) => g.mutate(title: "New Title"));
}

class FireCrud {
  Map<String, ModelCrud> models = {};
}

class ChildModel {
  /// The subCollection that this child is a part of
  final String collection;

  /// The document id that this child is a part of if it is exclusive otherwise keep this null
  final String? exclusiveDocumentId;

  /// The model that this child is a part of
  final ModelCrud model;

  ChildModel(this.collection, this.model, {this.exclusiveDocumentId});
}

mixin ModelCrud {
  List<ChildModel> get childModels;
}
