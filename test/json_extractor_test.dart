import 'package:json_extractor/json_extractor.dart';
import 'package:test/test.dart';

const testMap = <String, dynamic>{
  "id": 3,
  "name": "dart",
  "posts": [
    {
      "id": 5,
      "post": {"id": 10},
      "keyword": {"id": 3}
    },
    {
      "id": 6,
      "post": {"id": 7},
      "keyword": {"id": 3}
    },
  ]
};

const ex1 = [
  {'color': 'red', 'value': '#f00'},
  {'color': 'green', 'value': '#0f0'},
  {'color': 'blue', 'value': '#00f'},
  {'color': 'cyan', 'value': '#0ff'},
  {'color': 'magenta', 'value': '#f0f'},
  {'color': 'yellow', 'value': '#ff0'},
  {'color': 'black', 'value': '#000'}
];

const ex2 = <String, dynamic>{
  "id": "0001",
  "type": "donut",
  "name": "Cake",
  "ppu": 0.55,
  "batters": {
    "batter": [
      {"id": "1001", "type": "Regular"},
      {"id": "1002", "type": "Chocolate"},
      {"id": "1003", "type": "Blueberry"},
      {"id": "1004", "type": "Devil's Food"}
    ]
  },
  "topping": [
    {"id": "5001", "type": "None"},
    {"id": "5002", "type": "Glazed"},
    {"id": "5005", "type": "Sugar"},
    {"id": "5007", "type": "Powdered Sugar"},
    {"id": "5006", "type": "Chocolate with Sprinkles"},
    {"id": "5003", "type": "Chocolate"},
    {"id": "5004", "type": "Maple"}
  ]
};

const ex3 = <String, dynamic>{
  "items": [
    {
      "item": {
        "id": "0001",
        "type": "donut",
        "name": "Cake",
        "ppu": 0.6,
        "batters": {
          "batter": [
            {"id": "1001", "type": "Regular"},
            {"id": "1002", "type": "Chocolate"},
            {"id": "1003", "type": "Blueberry"},
            {"id": "1004", "type": "Devil's Food"}
          ]
        },
        "topping": [
          {"id": "5001", "type": "None"},
          {"id": "5002", "type": "Glazed"},
          {"id": "5005", "type": "Sugar"},
          {"id": "5007", "type": "Powdered Sugar"},
          {"id": "5006", "type": "Chocolate with Sprinkles"},
          {"id": "5003", "type": "Chocolate"},
          {"id": "5004", "type": "Maple"}
        ]
      }
    },
    {
      "item": {
        "id": "0002",
        "type": "donut",
        "name": "Raised",
        "ppu": 0.55,
        "batters": {
          "batter": [
            {"id": "1001", "type": "Regular"},
            {"id": "1002", "type": "Chocolate"}
          ]
        },
        "topping": [
          {"id": "5005", "type": "Sugar"},
          {"id": "5007", "type": "Powdered Sugar"},
          {"id": "5003", "type": "Chocolate"},
          {"id": "5004", "type": "Maple"}
        ]
      }
    }
  ]
};

void main() {
  group('Extracts data correctly on the example', () {
    const schemaResultsList = [
      [
        {'id': 'id'},
        {'id': 3}
      ],
      [
        {'posts': 'posts.post'},
        {
          'posts': [
            {"id": 10},
            {"id": 7}
          ]
        }
      ],
      [
        {'post_ids': 'posts.post.id'},
        {
          'post_ids': [10, 7]
        }
      ],
      [
        {'': ''},
        {'': null}
      ]
    ];

    for (final [schema as Map<String, String>, result] in schemaResultsList) {
      test('should extract data according to the schema $schema', () {
        expect(JsonExtractor(schema).process(testMap), result);
      });
    }
  });

  group('JSON 1 from the Internet', () {
    final colorNames = {'colorNames': ex1.map((e) => e.values.first).toList()};
    final colorCodes = {'colorCodes': ex1.map((e) => e.values.last).toList()};

    test('color names are extracted correctly', () {
      const extractor = JsonExtractor({'colorNames': 'color'});

      expect(extractor.process(ex1), colorNames);
    });

    test('color codes are extracted correctly', () {
      const extractor = JsonExtractor({'colorCodes': 'value'});

      expect(extractor.process(ex1), colorCodes);
    });
  });

  group('JSON 2 from the Internet', () {
    final batterTypes = {
      'batterTypes': ex2['batters']['batter'].map((map) => map['type']).toList()
    };

    final toppingIds = {
      'toppingIds': ex2['topping'].map((map) => map['id']).toList()
    };

    test('"batter types" extracted correctly', () {
      const extractor = JsonExtractor({'batterTypes': 'batters.batter.type'});

      expect(extractor.process(ex2), batterTypes);
    });

    test('"toppings" extracted correctly', () {
      const extractor = JsonExtractor({'toppingIds': 'topping.id'});

      expect(extractor.process(ex2), toppingIds);
    });
  });

  group('JSON 3 from the Internet', () {
    test('multiple keys are extracted correctly', () {
      final matcher = {
        'itemIds': ex3['items'].map((map) => map['item']['id']),
        'itemBatters':
            ex3['items'].map((map) => map['item']['batters']['batter']),
        'itemBatterTypes': ex3['items'].map((map) =>
            map['item']['batters']['batter'].map((bMap) => bMap['type'])),
        'missingField': []
      };

      const schema = {
        'itemIds': 'items.item.id',
        'itemBatters': 'items.item.batters.batter',
        'itemBatterTypes': 'items.item.batters.batter.type',
        'missingField': 'items.item.not.existent.path'
      };

      const extractor = JsonExtractor(schema);

      expect(extractor.process(ex3, includeMissingPathEntries: false), matcher);
    });
  });

  group('`processAsList` works correctly', () {
    test('clear unwanted nesting from the map {..., posts: [{id: id}]}', () {
      const clearKwdPostSchema = {'id': 'post.id'};

      final testMapMatcher = Map.of(testMap)
        ..update('posts', (list) => list.map((e) => e['post']).toList());

      const extractor = JsonExtractor(clearKwdPostSchema);

      final res = Map.of(testMap)
        ..update('posts', (value) => extractor.processAsList(value));

      expect(res, testMapMatcher);
    });

    // uses the ex1
    test('extract a list of maps [{name: colorName}, ...]', () {
      const colorNameSchema = {'color': 'color'};

      final ex1Matcher = ex1.map((e) => {'color': e['color']}).toList();

      const extractor = JsonExtractor(colorNameSchema);

      expect(extractor.processAsList(ex1), ex1Matcher);
    });

    // uses the ex3
    test(
        'extract a list of data according to the schema [{...item1}, {...item2}]',
        () {
      const itemsSchemaNew = {'...': 'item'};
      const extractor = JsonExtractor(itemsSchemaNew);
      final res = extractor.processAsList<Map>(ex3['items'], extract: true);

      final itemsMatcher = [for (final item in ex3['items']) item['item']];

      expect(res, itemsMatcher);
    });
  });

  group('`extract` option works correctly', () {
    // uses the ex1
    test('extract a list of maps {colors: [colorName0, colorName1, ...]}', () {
      const colorNameSchema = {'colors': 'color'};
      final nonExtractMatcher = {
        'colors': ex1.map((e) => e['color']).toList()
      }; // {colors: [list of color names]}
      final extractMatcher =
          nonExtractMatcher.values.first; // [list of color names]

      const extractor = JsonExtractor(colorNameSchema);

      expect(extractor.process(ex1), nonExtractMatcher);
      expect(extractor.process(ex1, extract: true), extractMatcher);
    });

    // uses the ex3
    test(
        'extract a list of data according to the schema '
        '[{...item1}, {...item2}]', () {
      const itemsSchemaNew = {'items': 'item'};
      const extractor = JsonExtractor(itemsSchemaNew);
      final res = extractor.process<List>(ex3['items'], extract: true);

      final itemsMatcher = [for (final item in ex3['items']) item['item']];

      expect(res, itemsMatcher);
    });
  });

  group('accepts maps of any type', () {
    const extractor = JsonExtractor({'name': 'user.name'});

    test('Map<dynamic, dynamic>', () {
      final json = <dynamic, dynamic>{
        'user': <dynamic, dynamic>{'name': 'a'}
      };

      expect(extractor.process(json), {'name': 'a'});
    });

    test('Map<Object?, Object?> nested in Map<String, dynamic>', () {
      final json = <String, dynamic>{
        'user': <Object?, Object?>{'name': 'a'}
      };

      expect(extractor.process(json), {'name': 'a'});
    });

    test('inside lists', () {
      final json = [
        <dynamic, dynamic>{
          'user': <dynamic, dynamic>{'name': 'a'}
        }
      ];

      expect(extractor.processAsList(json), [
        {'name': 'a'}
      ]);
    });
  });

  group('values that are not a Map or a List along the path', () {
    const extractor = JsonExtractor({'name': 'user.name'});

    test('produce null', () {
      expect(extractor.process({'user': 'bob'}), {'name': null});
      expect(extractor.process('oops'), {'name': null});
    });

    test('are omitted with includeMissingPathEntries: false', () {
      expect(
          extractor.process({'user': 'bob'}, includeMissingPathEntries: false),
          isEmpty);
    });

    test('produce null for the matching list entries', () {
      final json = {
        'user': [
          {'name': 'a'},
          'deleted',
          null,
        ]
      };

      expect(extractor.process(json), {
        'name': ['a', null, null]
      });
      expect(extractor.process(json, includeMissingPathEntries: false), {
        'name': ['a']
      });
    });
  });

  group('`extract` with a missing value', () {
    const extractor = JsonExtractor({'x': 'a'});

    test('returns null for a nullable type argument', () {
      expect(extractor.process({'b': 1}, extract: true), isNull);
      expect(extractor.process<List?>({'b': 1}, extract: true), isNull);
    });

    test('throws a FormatException for a non-nullable type argument', () {
      expect(
        () => extractor.process<List>({'b': 1}, extract: true),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            contains('type argument List<dynamic> is not nullable'))),
      );
      expect(
        () => extractor.processAsList<Map>([
          {'a': {}},
          {'b': 1}
        ], extract: true),
        throwsFormatException,
      );
    });

    test('uses the default', () {
      const extractor = JsonExtractor({'x': 'a'}, defaults: {'x': []});

      expect(extractor.process<List>({'b': 1}, extract: true), isEmpty);
    });
  });

  group('`keepNullsInLists` option', () {
    const extractor = JsonExtractor({
      'ids': 'items.id',
      'names': 'items.name',
      'missing': 'nothing',
    });
    const json = {
      'items': [
        {'id': 1, 'name': 'a'},
        {'id': 2},
        {'id': 3, 'name': 'c'},
      ]
    };

    test('removes nulls from lists by default', () {
      expect(extractor.process(json, includeMissingPathEntries: false), {
        'ids': [1, 2, 3],
        'names': ['a', 'c'],
      });
    });

    test('keeps lists aligned and still omits missing top-level keys', () {
      expect(
          extractor.process(json,
              includeMissingPathEntries: false, keepNullsInLists: true),
          {
            'ids': [1, 2, 3],
            'names': ['a', null, 'c'],
          });
    });
  });

  group('`strict` option', () {
    test('returns resolved paths and explicit nulls', () {
      const extractor =
          JsonExtractor({'name': 'user.name', 'email': 'user.contact.email'});

      expect(
        extractor.process({
          'user': {'name': 'a', 'contact': null}
        }, strict: true),
        {'name': 'a', 'email': null},
      );
    });

    test('throws on an absent key', () {
      expect(
        () => const JsonExtractor({'x': 'user.name'})
            .process({'user': {}}, strict: true),
        throwsA(isA<FormatException>().having((e) => e.message, 'message',
            'Cannot resolve path "user.name" at segment "name": the key is absent')),
      );
    });

    test('throws on a value that is not a Map or a List', () {
      expect(
        () => const JsonExtractor({'x': 'user.name'})
            .process({'user': 'bob'}, strict: true),
        throwsA(isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Cannot resolve path "user.name" at segment "name": '
                'expected a Map or a List, got String')),
      );
    });

    test('throws on a missing key inside a list', () {
      expect(
        () => const JsonExtractor({'x': 'items.id'}).process({
          'items': [
            {'id': 1},
            {}
          ]
        }, strict: true),
        throwsFormatException,
      );
    });

    test('throws on an out of range index', () {
      expect(
        () => const JsonExtractor({'x': 'items[2]'}).process({
          'items': [1, 2]
        }, strict: true),
        throwsA(isA<FormatException>().having(
            (e) => e.message,
            'message',
            'Cannot resolve path "items[2]" at segment [2]: '
                'index is out of range for a List of length 2')),
      );
    });
  });

  group('`defaults`', () {
    const extractor = JsonExtractor(
      {'name': 'user.name', 'age': 'user.age'},
      defaults: {'name': 'anonymous'},
    );

    test('replace null values', () {
      expect(
          extractor.process({'user': {}}), {'name': 'anonymous', 'age': null});
      expect(
        extractor.process({
          'user': {'name': null}
        }, includeMissingPathEntries: false),
        {'name': 'anonymous'},
      );
    });

    test('do not replace present values', () {
      expect(
        extractor.process({
          'user': {'name': 'a', 'age': 3}
        }),
        {'name': 'a', 'age': 3},
      );
    });
  });

  group('list indices', () {
    const json = {
      'items': [
        {
          'id': 1,
          'tags': ['a', 'b']
        },
        {
          'id': 2,
          'tags': ['c']
        },
      ]
    };

    test('select a list element', () {
      expect(const JsonExtractor({'x': 'items[1].id'}).process(json), {'x': 2});
      expect(
          const JsonExtractor({'x': 'items.[0].id'}).process(json), {'x': 1});
      expect(
          const JsonExtractor({'x': '[1]'}).processAsList([
            [1, 2],
            [3, 4]
          ]),
          [
            {'x': 2},
            {'x': 4}
          ]);
    });

    test('apply to each element of a traversed list', () {
      expect(const JsonExtractor({'x': 'items.tags[0]'}).process(json), {
        'x': ['a', 'c']
      });
      expect(const JsonExtractor({'x': 'items.tags[1]'}).process(json), {
        'x': ['b', null]
      });
    });

    test('chain', () {
      expect(
        const JsonExtractor({'x': 'm[1][0]'}).process({
          'm': [
            [1],
            [2, 3]
          ]
        }),
        {'x': 2},
      );
    });

    test('produce null when not applicable', () {
      expect(const JsonExtractor({'x': 'items[5]'}).process(json), {'x': null});
      expect(const JsonExtractor({'x': 'items[0].id[0]'}).process(json),
          {'x': null});
    });

    test('brackets without a number are part of the key', () {
      expect(const JsonExtractor({'x': 'a[b]'}).process({'a[b]': 1}), {'x': 1});
    });

    test('throw on characters after an index', () {
      expect(() => const JsonExtractor({'x': 'a[0]b'}).process({}),
          throwsArgumentError);
    });
  });

  group('escaping', () {
    test('a dot in a key', () {
      expect(
        const JsonExtractor({'x': r'version\.major'}).process({
          'version.major': 1,
          'version': {'major': 2}
        }),
        {'x': 1},
      );
    });

    test('a bracket and a backslash in a key', () {
      expect(
          const JsonExtractor({'x': r'a\[0]'}).process({'a[0]': 1}), {'x': 1});
      expect(
          const JsonExtractor({'x': r'a\\.b'}).process({
            r'a\': {'b': 1}
          }),
          {'x': 1});
    });

    test('other backslashes are literal', () {
      expect(const JsonExtractor({'x': r'a\b'}).process({r'a\b': 1}), {'x': 1});
    });
  });
}
