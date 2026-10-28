## 1.2.0

- Fixed maps that are not `Map<String, dynamic>` (e.g. `Map<dynamic, dynamic>` from `Map.from`, YAML or platform
  channels) causing an `ArgumentError`.
- Values along a path that are not a Map or a List now produce `null` instead of throwing an `ArgumentError`.
- `extract: true` with a non-nullable type argument now throws a descriptive `FormatException` instead of a `TypeError`
  when the extracted value is null.
- Added the `strict` option to throw a `FormatException` on missing paths.
- Added the `keepNullsInLists` option to keep extracted lists index-aligned with `includeMissingPathEntries: false`.
- Added the `defaults` constructor parameter for the values of null results.
- Added list index segments (`items[0].id`) and escaping (`\.`, `\[`, `\\`) in schema paths. Paths that contained
  `[<digits>]` or these escape sequences in keys are now interpreted differently.
- `processAsList` now parses the schema once instead of for every element.
- Raised the minimum Dart SDK version to `3.0.0`.
- Fixed outdated documentation.

## 1.1.2

- Fixed some mistakes in the README.

## 1.1.1

- Raised the maximum Dart SDK version to support Dart 3.
- Added the issue tracker link to the pubspec file.

## 1.1.0

- Fixed the signature of the methods, so they can take JSON in any cases.
- Added support for JSON arrays with `processAsList` method.
- Added the `extract` option to both `process` and `processAsList` methods.

## 1.0.2

- Changed minimal SDK version to `2.12.0` to indicate the full null-safety support.

## 1.0.1

- Extended `pub.dev` package description.

## 1.0.0

- Initial version.
