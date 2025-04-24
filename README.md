CRUD operations for Firestore

> I have gotten sick and tired of firebases poor mapping system, and tired of having to make something like this but half baked for every project i start. Inf is already boring enough, so lets stop doing so much of it.

```dart
flutter pub add fire_crud
flutter pub add fire_crud_gen --dev
```

# Setup
This project uses [fire_api](https://pub.dev/packages/fire_api) for the firestore database. You will need to set it up before you can use this package.

## Features

* Get,Set,Add,Stream,,Delete documents as models
* Get,Stream,Count,Walk collections

## Usage

1. Define your models
```dart
class User with ModelCrud {
  String name;
  int age;

  // copyWith, toMap, fromMap would be from dart_mappable for example

  @override
  List<ChildModel> get childModels => [
    // user/USERID/data/settings
    ChildModel<Usersettings>(
        collection: "data",
        exclusiveDocumentId: "settings",
        model: UserSettings(), 
        toMap: (m) => m.toMap(), 
        fromMap: (m) => UserSettingsMappable.fromMap(m)),
    
    // user/USERID/note/NOTEID
    ChildModel<Note>(
        collection: "note",
        model: Note(), 
        toMap: (m) => m.toMap(), 
        fromMap: (m) => NoteMappable.fromMap(m)),
  ];
}

class UserSettings with ModelCrud {
  bool dark;
  
  @override
  List<ChildModel> get childModels => [];
}

class Note with ModelCrud {
  String title;
  String content;
  
  @override
  List<ChildModel> get childModels => [];
}

// On init we need to register all root models
void main(){
  $crud.registerModel(ChildModel<User>(
    collection: "user",
    model: User(),
    toMap: (m) => m.toMap(),
    fromMap: (m) => UserMappable.fromMap(m)
  ));
}
```

2. Run the build runner!
3. Use them!

```dart
// Add a user
User user = await $crud.addUser(User()..name = "Dan" ..age = 21);

// Add a note without getting the user by using .model instead of .pull
Note added = await $crud.model<User>("USERID")
  .addNote(Note()
      ..title = "My Note"
      ..content = "This is my note");

// Update a note 
await user.setNote(added..title = "My new note");

// Update a note atomically (txn get then set)
await user.setAtomicNote((now) => now..title = "My new note");

// Select all notes ordered by title
List<Note> notes = await user.getNotes(query: (q) => q.orderBy("title"));

// Stream all notes
Stream<List<Note>> notesStream = user.streamNotes();

// Get neighbor note
added.parentModel<User>().getNote("another id");

// Delete
user.deleteNote("noteID");

// Delete the user
user.delete();
```