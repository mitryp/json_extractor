[![Dart Tests](https://github.com/mitryp/json_extractor/actions/workflows/dart_tests.yml/badge.svg?branch=master)](https://github.com/mitryp/json_extractor/actions/workflows/dart_tests.yml)
[![pub package](https://img.shields.io/pub/v/json_extractor.svg)](https://pub.dev/packages/json_extractor)
[![package publisher](https://img.shields.io/pub/publisher/json_extractor.svg)](https://pub.dev/packages/json_extractor/publisher)

### Extracting nested JSON values

`json_extractor` is a miniature library providing the functionality of schema-driven extracting and flattening JSON values.
Supports nested maps and lists and outputs data as a one-layered Map with a user-defined structure.

## Features

* Extracting deeply nested maps and lists in any nesting order.
* Simple path-like schemas: `user_names: users.user.name`.
* List indices and escaping: `first_tag: tags[0]`, `major: version\.major`.
* Compile-time constant reusable JsonExtractor instances.
* Simple flat maps with only needed data as a result.

## Getting started

To start, install the package, import `JsonExtractor` class, and create a [schema](#schema) for it.
Then, create a `JsonExtractor` object with the created schema and use its `process` method to extract values:

```dart
// prefer constant initialization
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

### JSON Arrays
REST APIs often supply JSON arrays to represent a collection of records. `JsonExtractor` can be used to extract values
from arrays using `processAsList` method of the extractor. It takes a `List<dynamic>` and applies the schema to each of
the elements in the list. It returns a list of the extracted maps:
```dart
const data = [
  {
    'id': 1,
    'name': {'name': 'Dmytro', 'nickname': 'mitryp'},
  },
  {
    'id': 2,
    'name': {'name': 'Kateryna', 'nickname': 'kathalie'},
  },
];

const extractor = JsonExtractor({'id': 'id', 'nickname': 'name.nickname'});
extractor.processAsList(data); // [{id: 1, nickname: mitryp}, {id: 2, nickname: kathalie}]
```

Consider a situation in which you need to extract only a list of values and don't need a map at all. In this case,
`extract: true` option can be used as follows:
```dart
const extractor = JsonExtractor({'anything': 'name.nickname'}); // instead of 'anything' can be literally anything 
                                                                // as this key will be extracted
// using the data from the previous example
extractor.processAsList(data, extract: true); // [mitryp, kathalie]
```

More examples can be found in the `example/json_extractor_example.dart` file.

## Schema

Schema is a `Map<String, String>` in which keys are used as keys in the resulting map, and the values are the paths to the
values in the processed maps.

Paths are the keywords divided by the dots: `key1.key2.key3...`.

The keywords can lead through nested maps and lists: `mapKey.listKey.innerMapKey...`. When a path reaches a list, the
rest of the path is applied to each of its elements.

A list element can be selected by its index: `items[0].id`, `matrix[1][0]`. A segment consisting only of an index
indexes the current value, e.g. `[0]` for a top-level list.

Use `\.`, `\[` and `\\` to include a literal `.`, `[` or `\` in a key: `r'version\.major'` reads the `version.major`
key.

## Missing values

A path is missing when a key is absent, an index is out of range, or a value along the path is not a map or a list.
Missing paths produce `null`. The following options of `process` and `processAsList` change that:

* `includeMissingPathEntries: false` omits keys with null values from the result and removes nulls from extracted lists.
* `keepNullsInLists: true` keeps the nulls in extracted lists, so that lists extracted from the same records stay
  index-aligned, while still omitting null top-level keys.
* `strict: true` throws a `FormatException` describing the unresolved path instead. A `null` value along the path is
  not considered missing.

Default values for the null results can be provided per schema key:

```dart
const extractor = JsonExtractor(
  {'name': 'user.name', 'tags': 'user.tags'},
  defaults: {'name': 'anonymous', 'tags': []},
);
extractor.process({'user': {}}); // {name: anonymous, tags: []}
```

When using `extract: true` with a non-nullable type argument, such as `process<List>(...)`, a null result throws a
`FormatException`. Use a nullable type argument (`process<List?>(...)`) or a default value.

## Issues and improvement suggestions

Feel free to open new issues and PRs at the project's [GitHub](https://github.com/mitryp/json_extractor).
