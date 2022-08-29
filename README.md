### Extracting nested JSON values

`json_extractor` is a miniature library providing the functionality of schema-driven extracting and flattening JSON values.
Supports nested maps and lists and outputs data as a one-layered Map with a user-defined structure.

## Features

* Extracting deeply nested maps and lists in any nesting order.
* Simple path-like schemas: `user_names: users.user.name`.
* Compile-time constant reusable JsonExtractor instances.
* Simple flat maps with only needed data as a result.

## Getting started

To start, install the package, import JsonExtractor class, and create a [schema](#schema) for it.
Then, create a JsonExtractor object with the created schema and use its `process` method to extract values:

```dart
// prefer the `const` initializing
const extractor = JsonExtractor(schema);
final res = extractor.process(json);
```

That will extract the values from the given paths in the schema

## Usage

When working with deeply nested maps with internal lists, it's necessary to create complex nested get-key and `Iterable.map`
invocations:

```dart
final pastry = {
  'itemIds': pastryMap['items'].map((map) => map['item']['id']), // almost ok
  'itemBatters': pastryMap['items'].map((map) => map['item']['batters']['batter']), // worse
  'itemBatterTypes': pastryMap['items'].map((map) => map['item']['batters']['batter'].map((bMap) => bMap['type'])) // oh
};
```

With `JsonExtractor` it can be simplified in the way below:
```dart
const schema = {
  'itemIds': 'items.item.id',
  'itemBatters': 'items.item.batters.batter',
  'itemBatterTypes': 'items.item.batters.batter.type'
};
final pastry = const JsonExtractor(schema).process(pastryMap);
```

More detailed example can be found in the `example/json_extractor_example.dart` file.

## Schema

Schema is a `Map<String, String>` in which keys are used as keys in the resulting map, and the values are the paths to the
values in the processed maps.

Paths are the keywords divided by the dots: `key1.key2.key3...`.

The keywords can lead through nested maps and lists: `mapKey.listKey.innerMapKey...`.

## Docs
More detailed documentation can be found [here](https://pub.dev/documentation/json_extractor/latest/).

## Issues and improvement suggestions

Feel free to open new issues and PRs at the project's [GitHub](https://github.com/mitryp/json_extractor).