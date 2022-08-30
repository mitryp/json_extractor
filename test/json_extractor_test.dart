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
    test('should extract data according to the schema', () {
      for (final schemaResult in schemaResultsList) {
        final extractor = JsonExtractor(schemaResult[0] as Map<String, String>);

        expect(extractor.process(testMap), schemaResult[1]);
      }
    });
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

  group('processList() works correctly', () {
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
      const itemsSchema = {
        // todo make it useful and not making rewrite all map by hand
        'id': 'item.id',
        'type': 'item.type',
        'name': 'item.name',
        'ppu': 'item.ppu',
        'batters': 'item.batters',
        'topping': 'item.topping'
      };
      const extractor = JsonExtractor(itemsSchema);
      final res = extractor.processAsList(ex3['items']);

      const itemsSchemaNew = {'...item': 'item'};
      const extractorNew = JsonExtractor(itemsSchemaNew);
      final resNew = extractorNew.processAsList(ex3['items']);

      final itemsMatcher = [for (final item in ex3['items']) item['item']];

      expect(res,
          resNew); // extraction implementation should be equal to the old one
      expect(resNew, itemsMatcher); // and they both should work correctly
    });
  });
}
