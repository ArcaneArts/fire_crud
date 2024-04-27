CRUD operations for Firestore

> I have gotten sick and tired of firebases poor mapping system, and tired of having to make something like this but half baked for every project i start. Inf is already boring enough, so lets stop doing so much of it.

## Features

* Get,Set,Add,Stream,Exists,GetOrSet,Delete,Update documents
* Get,Stream,Walk collections
* Track usage & cost
* Typed documents using your own mappers instead of firebases built in mapper (it gets weird on certain types and is unreliable)

## Usage

Example Serializable Person class
```dart
part 'person.g.dart';

@JsonSerializable()
class Person {
  @JsonKey(ignore: true) String? uid; // Optionally track a uid for ease of use in widgets
  @JsonKey(ignore: true) bool exists = true; // Optionally track if the document exists
  
  String? name;
  int? age;
  //...
}
```

```dart
import 'package:fire_crud/fire_crud.dart';

class MyCrud {
  static FireCrudEvent _usage = FireCrudEvent();
  
  static FireCrud<Person> get people =>
      FireCrud<Person>(
        // The collection to use
        collection: FirebaseFirestore.instance.collection("people"),
        
        // The mapper to use
        toMap: (t) => Person.toJson(t),
        
        // The reverse mapper to use
        fromMap: (id, map) => Person.fromJson(map)
          ..uid = id, // Optionally track a uid for ease of use in widgets
        
        // Optionally track usage
        usageTracker: (event) => _usage += event),
  
        // Optionally define an empty object to use when a document is not found
        // Unless using getOrNull / streamOrNull, stream & get will return a non null
        // deserialized object with all fields set to null. You can change this default here
        emptyObject: Person()..exists = false,
      );
}
```
## Stream Large Lists Efficiently
```dart
Scaffold(
  body: FireList<Person>(
    crud: MyCrud.people,
    builder: (context, person) => PersonTile(person),

    // Below are typical options but are all optional
    query: (q) => q.where("age", isGreaterThan: 18), // only adults
    loading: ListTile();
    failed: SizedBox.shrink(),
    physics: BouncingScrollPhysics(),
  )
)
```

## Single Document Operations
You can manage individual documents using the following methods

### Add Documents
```dart
// Add a document
String theId = await MyCrud.people
    .add(Person(name: "Bob", age: 42));
```

### Get Documents
```dart
// Get a document (will use the empty object if not found)
Person bob = await MyCrud.people
    .get(theId);

// Get a document or null
Person? bobOrNull = await MyCrud.people
    .getOrNull(theId);

// Get a document or just return something else if it doesnt exist
Person bobOrSomethingElse = await MyCrud.people
    .getOrReturn(theId, () => Person(name: "Bob", age: 42));

// Get a document or set it if not found
Person bobOrSet = await MyCrud.people
    .getOrSet(theId, () => Person(name: "Bob", age: 42));
```

### Delete Documents
```dart
// Delete a document
await MyCrud.people
    .delete(theId);
```

### Update Documents
```dart

// Update a document
await MyCrud.people
    .update(theId, {
        "age": FieldValue.increment(1),
    });
```

### Stream Documents
```dart
// Stream a document (will use the empty object if not found)
Stream<Person> bobStream = MyCrud.people
    .stream(theId);

// Stream a document or null
Stream<Person?> bobStreamOrNull = MyCrud.people
    .streamOrNull(theId);

// Stream a document or just return something else if it doesnt exist
Stream<Person> bobStreamOrSomethingElse = MyCrud.people
    .streamOrReturn(theId, () => Person(name: "Bob", age: 42));
```

## Collection Operations
You can manage collections using the following methods

Counting using aggregate queries
```dart
// Count the number of documents in a collection
int count = await MyCrud.people
    .count();

// You can also use a query as a counting filter or limiter
int count = await MyCrud.people
    .count({
        query: (q) => q.where("age", isGreaterThan: 18) // only count adults
                      .limit(1000), // will use up to one read only
    });
```

### Get Collections
```dart
// Get all the people
Iterable<Person> people = await MyCrud.people
    .getAll();

// Get all the people with a query
Iterable<Person> people = await MyCrud.people
    .getAll({
        query: (q) => q.where("age", isGreaterThan: 18) // only get adults
                      .limit(100) // will use up to 100 reads,
    });
```

### Stream Collections
```dart
// Stream all the people
Stream<Person> peopleStream = MyCrud.people
    .streamAll();

// Stream all the people with a query
Stream<Person> peopleStream = MyCrud.people
    .streamAll({
        query: (q) => q.where("age", isGreaterThan: 18) // only get adults
                      .limit(100) // will use up to 100 reads per update,
    });
```

### Walk Collections
See [collection_walker](https://pub.dev/packages/collection_walker) for more info. You may not need to add it unless you are using its types.
```dart
CollectionWalker<Person> walker = MyCrud.people
    .walk({
        query: (q) => q.where("age", isGreaterThan: 18) // only get adults
                      .limit(100) // will use up to 100 reads per update,
        chunkSize: 50 // The default
    });

// Then in a widget for infinite scrolling recycler list!
FutureBuilder<int>(
    future: walker.size(), // cached if it already knows it
    builder: (_, snap) => !snap.hasData ? ListView() : ListView.builder(
        itemCount: snap.data,
        itemBuilder: (_, i) => FutureBuilder<Person>(
            future: walker.get(i),
            builder: (_, snap) => !snap.hasData ? const LoadingListTile() : ListTile(
                title: Text(snap.data!.name),
                subtitle: Text(snap.data!.age.toString()),
            ),
        ),
    ),
);
```

## Subcollections
Subcollections are actually really easy to deal with

```dart
import 'package:fire_crud/fire_crud.dart';

class MyCrud {
  static FireCrudEvent _usage = FireCrudEvent();
  
  static FireCrud<Person> get people => ...
  
  // Basically just use a method to take in the parent id and return a new crud
  static FireCrud<Friend> friend(String person) => FireCrud<Person>(
      // The collection to use
      collection: FirebaseFirestore.instance.collection("people/$person/friends"),

      // The mapper to use
      toMap: (t) => Person.toJson(t),

      // The reverse mapper to use
      fromMap: (id, map) => Person.fromJson(map)
        ..uid = id, // Optionally track a uid for ease of use in widgets

      // Optionally track usage
      usageTracker: (event) => _usage += event),
    
      // Optionally define an empty object to use when a document is not found
      // Unless using getOrNull / streamOrNull, stream & get will return a non null
      // deserialized object with all fields set to null. You can change this default here
      emptyObject: Person()..exists = false,
  );
}
```

## Usage Tracking
You can track usage by passing in a usage tracker to the crud. This will track the number of reads, writes, and deletes. It will also track the number of documents read, written, and deleted. This can be used to track usage and cost.

```dart
import 'package:fire_crud/fire_crud.dart';

final FireCrudEvent _usage = FireCrudEvent();

// tune your costs. You can modify these fields to match your firestore costs
// The free tier is ignored this assumes you are paying for every rwd
void setupCosts(){
  kFireCrudCostPerRead = 0.0345 / 100000.0;
  kFireCrudCostPerWrite = 0.1042 / 100000.0;
  kFireCrudCostPerDelete = 0.0115 / 100000.0;
}

double calculateCost() => _usage.cost;
```