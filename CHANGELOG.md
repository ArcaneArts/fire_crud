## 2.1.0
* **BREAKING** Removed push in favor of set, setUnique
* **BREAKING** Removed pushAtomic in favor of setAtomic, setUniqueAtomic
* **BREAKING** Removed pull in favor of get, getUnique
* **BREAKING** Changed stream([id]) into stream(id) and streamUnique()
* **BREAKING** Changed delete([id]) into delete(id) and deleteUnique()
* **BREAKING** Changed model([id]) into model(id) and modelUnique()
* **BREAKING** Renamed `ChildModel` to `FireModel`
* Streams of single models return nullable results now
* Added a quick getter for `FireCrud.instance()` as `$fcrud` global variable

## 2.0.8
* Added set(id) and setUnique() in favor of now deprecated `push([id?])`
* Added setAtomic(id) and setUniqueAtomic() in favor of now deprecated `pushAtomic([id?])`
* Added get(id) and getUnique() in favor of now deprecated `pull([id?])`

## 2.0.7
* Deletes dont require a model

## 2.0.6
* Ensure exists method call

## 2.0.5
* Drop flutter dependency as we dont need it anymore. Now dart can work also.

## 2.0.4
* Fixes

## 2.0.3
* Collection Viewers, typically useful for maintaining a live view of a changing window of data in a collection under a query. I.e. the backend of a listview.builder in flutter even.

## 2.0.2
* Get self ChildModel from ModelCrud

## 2.0.1
* Docs

## 2.0.0
* Switched to fire_api

## 1.1.9
* Updated Cloud Firestore Constraint to '>=0.27.0 <1.0.0'
* Updated RXDart Constraint to '>=0.27.0 <1.0.0'

## 1.1.8

* Filter options for FireList, FireSliverSlist, FireGrid

## 1.1.7

* Logging for collection viewers
* Dump cache on size changes

## 1.1.6

* Fix collection viewers not updating when becoming empty

## 1.1.5

* Attempt to fix collection viewers not updating when already empty
* Added FireSliverList<T> variant of FireList<T>

## 1.1.4

* Fire Grids fixed

## 1.1.3

* Fire Grids


## 1.1.2

* Empty widget for FireLists
* Blank object getter in crud (define emptyObject to use)

## 1.1.1

* Remove logging calls in fire lists

## 1.1.0

* Fire Lists

## 1.0.2

* Add transactions with txn("doc", (T in) => T out)
* Add getCached("doc") which tries to read the cache before the server


## 1.0.1

* Create stream builders

## 1.0.0

* Initial Release
