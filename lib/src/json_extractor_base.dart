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
  const JsonExtractor(this.schema);

  static const listSpreadMark = '...';

  /// A schema of the Map values to be extracted.
  ///
  /// The schema is a Map<String, String>, that has the following structure:
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
  final Map<String, String> schema;

  /// Extracts the given Map or List according to this object's schema.
  ///
  /// The [includeMissingPathEntries] option defines the object behaviour when parsing schema paths that
  /// do not exist in the processed map. When true, the keys of the missing paths will have the
  /// value of null. When false, the resulting map will not contain keys that have the value of
  /// null (unless that values are included in an object that was not parsed). By default, true.
  ///
  /// When the map includes internal list of maps, they are processed recursively according to the
  /// schema path reminder applied to the maps inside the list.
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
  Map<String, dynamic> process(dynamic json,
      {bool includeMissingPathEntries = true}) {
    final res = <String, dynamic>{};

    for (final declaration in schema.entries) {
      final resKey = declaration.key;
      final pathSegments = declaration.value.split('.').toList(growable: false);
      final value =
          _extractValueFromPath(json, pathSegments, includeMissingPathEntries);

      if (value != null || includeMissingPathEntries) {
        res[resKey] = value;
      }
    }

    if (schema.length == 1 && schema.keys.first.startsWith(listSpreadMark)) {
      return res[schema.keys.first];
    }

    return res;
  }

  /// Extracts the list of Maps or List according to the [schema] of this [JsonExtractor].
  ///
  /// Applies the schema to each entry of the [jsonList].
  ///
  /// Returns a list of the extracted maps.
  ///
  List<Map<String, dynamic>> processAsList(List<dynamic> jsonList,
      {bool includeMissingPathEntries = true}) {
    return jsonList
        .map((json) =>
            process(json, includeMissingPathEntries: includeMissingPathEntries))
        .toList();
  }

  /// Extracts the value which is located among the specified path in the given map.
  ///
  dynamic _extractValueFromPath(
      dynamic json, List<String> pathSegments, bool includeMissingPathEntries) {
    dynamic currentLayer = json;

    for (var layerIdx = 0; layerIdx < pathSegments.length; layerIdx++) {
      final pathSegment = pathSegments[layerIdx];

      if (currentLayer == null) {
        break;
      }

      if (currentLayer is List<Map<String, dynamic>>) {
        currentLayer = _extractListEntries(currentLayer,
            pathSegments.sublist(layerIdx), includeMissingPathEntries);
        break;
      } else if (currentLayer is Map<String, dynamic>) {
        currentLayer = currentLayer[pathSegment];
      } else {
        throw ArgumentError(
            'Segment "$pathSegment" of the path should be a Map or a List, but it was ${currentLayer.runtimeType} ("$currentLayer")');
      }
    }

    return currentLayer;
  }

  /// Recursively extracts values from the list containing Maps<String, dynamic> according to the
  /// remaining path segments obtained from the schema during parsing.
  ///
  List<dynamic> _extractListEntries(List<Map<String, dynamic>> list,
      List<String> pathSegments, bool includeMissingPathEntries) {
    var res = list.map((map) =>
        _extractValueFromPath(map, pathSegments, includeMissingPathEntries));

    if (!includeMissingPathEntries) {
      res = res.where((e) => e != null);
    }

    return res.toList();
  }
}
