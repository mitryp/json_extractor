/// A class providing the functionality of flattening nested Map and List objects using the schemas.
///
/// To flatten JSON, create the object of the [JsonExtractor] with the [schema] as
/// the argument and use the [process] method of the object to extract the values according to the
/// provided schema.
///
/// See the [process] method documentation for reference.
///
/// Objects of the class can be created as a compile-time constants.
///
class JsonExtractor {
  /// Creates an instance of [JsonExtractor] with the given [schema].
  ///
  /// See the [schema] documentation for schema structure reference.
  ///
  const JsonExtractor(this.schema, {this.defaults = const {}});

  /// A schema of the Map values to be extracted.
  ///
  /// The schema is a `Map<String, String>`, that has the following structure:
  /// ```
  /// {
  ///   'fieldName1': 'key1',
  ///   'fieldName2': 'key2.key3.key4'  // and so on
  ///   // ...
  /// }
  /// ```
  /// where `fieldName` is the String name of the key in the resulting map and its value is the
  /// path of keys in the Map to the needed value to be followed by. The value of the last
  /// key will be included to the resulting Map.
  ///
  /// A path segment can select a list element by its index: `items[0].id`.
  /// A segment consisting only of an index (`[0].id`) indexes the current
  /// value directly.
  ///
  /// Use `\.`, `\[` and `\\` to include a literal `.`, `[` or `\` in a key:
  /// `r'version\.major'` reads the `version.major` key.
  ///
  final Map<String, String> schema;

  /// The values to use for the [schema] keys whose extracted value is null.
  final Map<String, dynamic> defaults;

  static final _indexPattern = RegExp(r'\[(\d+)\]');

  /// Extracts the given Map or List according to this object's schema.
  ///
  /// The [includeMissingPathEntries] option defines the object behaviour when
  /// parsing schema paths that do not exist in the processed map. When true,
  /// the keys of the missing paths will have the value of null. When false,
  /// the resulting map will not contain keys that have the value of null
  /// (unless that values are included in an object that was not parsed), and
  /// null values are removed from the lists extracted along the path.
  /// By default, true.
  ///
  /// Removing nulls from lists makes lists extracted from the same source
  /// lose their index alignment. Set [keepNullsInLists] to true to keep them
  /// while still omitting the null top-level keys.
  /// By default, false.
  ///
  /// A path is missing when a key is absent, an index is out of range, or a
  /// value along the path is not a Map or a List. When [strict] is true,
  /// missing paths throw a [FormatException] instead of producing null.
  /// A null value along the path is not considered missing.
  /// By default, false.
  ///
  /// When the resulting map contains only one key-value pair, it may be
  /// more convenient to extract the value and remove unnecessary nesting.
  /// To do it, the [extract] option is used.
  /// When is set to `true`, the value of the only key of the resulting map will
  /// be returned instead of the map.
  /// > Note that if the quantity of the declarations in the schema is not equal
  ///   to **1**, setting the `extract` to true will cause ArgumentError.
  /// By default, false.
  ///
  /// Returns the `dynamic` type by default, but the return type can be specified
  /// as a type parameter of the method.
  /// > At the same time, the type parameter *should not contain specified
  ///   internal types*. For example, use `process<List>(...)` when you expect to
  ///   get any list from a json.
  ///
  /// When [extract] is true and the extracted value is null, a non-nullable
  /// type parameter causes a [FormatException]. Use a nullable type
  /// (`process<List?>(...)`) or provide a value in [defaults].
  ///
  /// When the map includes internal list of maps, they are processed
  /// recursively according to the schema path remainder applied to the maps
  /// inside the list.
  ///
  /// For example, imagine having a map of the following structure:
  /// ```dart
  /// const Map<String, dynamic> testMap = {
  ///   "id": 3,
  ///   "name": "dart",
  ///   "posts": [
  ///     {
  ///       "id": 5,
  ///       "post": {"id": null},
  ///       "keyword": {"id": 3}
  ///     },
  ///     {
  ///       "id": 6,
  ///       "post": {"id": 7},
  ///       "keyword": {"id": 3}
  ///     }
  ///   ]
  /// };
  /// ```
  /// To retain only the wanted data from the map, use the [JsonExtractor] as in the example below:
  /// ```dart
  /// // create a JsonExtractor object with a desired schema
  /// // the keys of the map will be the keys in the result; the values of the keys are paths to the
  /// // needed values in the processed map.
  /// const extractor = JsonExtractor({
  ///     'id': 'id',  // the key will be used as a key for the value that has the path in the value of the schema
  ///     'name': 'name',
  ///     'posts': 'posts.post'  // if the map has internal lists that contain other maps, they will be processed recursively
  /// });
  ///
  /// final res = extractor.process(testMap);
  /// ```
  /// The result will have the following structure:
  /// ```dart
  /// {
  ///   'id': 3,
  ///   'name': 'dart',
  ///   'posts': [
  ///     {'id': null},
  ///     {'id': 7}
  ///   ]
  /// }
  /// ```
  T process<T extends dynamic>(
    dynamic json, {
    bool includeMissingPathEntries = true,
    bool extract = false,
    bool keepNullsInLists = false,
    bool strict = false,
  }) {
    _checkExtract(extract);

    return _process<T>(
      json,
      _parseSchema(),
      _Options(includeMissingPathEntries, keepNullsInLists, strict),
      extract,
    );
  }

  /// Extracts the list of Maps or List according to the [schema] of this [JsonExtractor].
  ///
  /// Applies the schema to each entry of the [jsonList].
  ///
  /// Returns a list of the extracted maps.
  ///
  /// The expected type of the list elements can be specified with a type
  /// parameter (some limitations apply, see [process] method documentation for
  /// reference).
  ///
  /// The [includeMissingPathEntries], [extract], [keepNullsInLists] and
  /// [strict] options do the same as the same options in the [process] method.
  ///
  List<T> processAsList<T extends dynamic>(
    List<dynamic> jsonList, {
    bool includeMissingPathEntries = true,
    bool extract = false,
    bool keepNullsInLists = false,
    bool strict = false,
  }) {
    _checkExtract(extract);

    final paths = _parseSchema();
    final options =
        _Options(includeMissingPathEntries, keepNullsInLists, strict);

    return [
      for (final json in jsonList) _process<T>(json, paths, options, extract)
    ];
  }

  void _checkExtract(bool extract) {
    if (extract && schema.length != 1) {
      throw ArgumentError('When using `extract = true` option, the schema '
          'must contain exactly one declaration, which will be extracted as a '
          'result; it had ${schema.length} declarations instead');
    }
  }

  List<_Path> _parseSchema() => [
        for (final declaration in schema.entries)
          _Path(
              declaration.key, declaration.value, _parsePath(declaration.value))
      ];

  /// Splits the [path] into String keys and int list indices.
  static List<Object> _parsePath(String path) {
    final segments = <Object>[];
    final key = StringBuffer();
    var segmentHasIndex = false;

    void endSegment() {
      if (!segmentHasIndex) segments.add(key.toString());
      key.clear();
      segmentHasIndex = false;
    }

    for (var i = 0; i < path.length; i++) {
      final char = path[i];
      final indexMatch =
          char == '[' ? _indexPattern.matchAsPrefix(path, i) : null;

      if (char == r'\' &&
          i + 1 < path.length &&
          const ['.', '[', r'\'].contains(path[i + 1])) {
        if (segmentHasIndex) _throwMalformedPath(path, i);
        key.write(path[++i]);
      } else if (char == '.') {
        endSegment();
      } else if (indexMatch != null) {
        if (!segmentHasIndex && key.isNotEmpty) segments.add(key.toString());
        segments.add(int.parse(indexMatch[1]!));
        segmentHasIndex = true;
        i = indexMatch.end - 1;
      } else {
        if (segmentHasIndex) _throwMalformedPath(path, i);
        key.write(char);
      }
    }
    endSegment();

    return segments;
  }

  static Never _throwMalformedPath(String path, int position) {
    throw ArgumentError.value(
        path, 'schema', 'Expected "." or "[" after "]" at position $position');
  }

  T _process<T>(
      dynamic json, List<_Path> paths, _Options options, bool extract) {
    final res = <String, dynamic>{};

    for (final path in paths) {
      final value =
          _extractValueFromPath(json, path, 0, options) ?? defaults[path.key];

      if (value != null || options.includeMissingPathEntries) {
        res[path.key] = value;
      }
    }

    if (extract) {
      final key = paths.first.key;
      final value = res[key];

      if (value == null && null is! T) {
        throw FormatException(
            'The value of "$key" (path "${paths.first.source}") '
            'is null, but the type argument $T is not nullable; use a nullable '
            'type argument or provide a default for "$key"');
      }

      return value as T;
    }

    return res as T;
  }

  /// Extracts the value located at the [path] segments from [start] onward in the given [json].
  ///
  dynamic _extractValueFromPath(
      dynamic json, _Path path, int start, _Options options) {
    dynamic currentLayer = json;

    for (var i = start; i < path.segments.length; i++) {
      if (currentLayer == null) {
        return null;
      }

      final segment = path.segments[i];

      if (segment is int) {
        if (currentLayer is List && segment < currentLayer.length) {
          currentLayer = currentLayer[segment];
        } else if (currentLayer is List) {
          return _missing(path, i, options,
              'index is out of range for a List of length ${currentLayer.length}');
        } else {
          return _missing(path, i, options,
              'expected a List, got ${currentLayer.runtimeType}');
        }
      } else if (currentLayer is List) {
        return _extractListEntries(currentLayer, path, i, options);
      } else if (currentLayer is Map) {
        if (options.strict && !currentLayer.containsKey(segment)) {
          return _missing(path, i, options, 'the key is absent');
        }
        currentLayer = currentLayer[segment];
      } else {
        return _missing(path, i, options,
            'expected a Map or a List, got ${currentLayer.runtimeType}');
      }
    }

    return currentLayer;
  }

  static Object? _missing(
      _Path path, int index, _Options options, String reason) {
    if (!options.strict) return null;

    final segment = path.segments[index];
    final segmentName = segment is int ? '[$segment]' : '"$segment"';

    throw FormatException(
        'Cannot resolve path "${path.source}" at segment $segmentName: $reason');
  }

  /// Recursively extracts values from the [list] according to the [path]
  /// segments from [start] onward.
  ///
  List<dynamic> _extractListEntries(
      List<dynamic> list, _Path path, int start, _Options options) {
    final res = [
      for (final entry in list)
        _extractValueFromPath(entry, path, start, options)
    ];

    if (!options.includeMissingPathEntries && !options.keepNullsInLists) {
      res.removeWhere((e) => e == null);
    }

    return res;
  }
}

class _Path {
  const _Path(this.key, this.source, this.segments);

  /// The key in the resulting map.
  final String key;

  final String source;

  final List<Object> segments;
}

class _Options {
  const _Options(
      this.includeMissingPathEntries, this.keepNullsInLists, this.strict);

  final bool includeMissingPathEntries;
  final bool keepNullsInLists;
  final bool strict;
}
