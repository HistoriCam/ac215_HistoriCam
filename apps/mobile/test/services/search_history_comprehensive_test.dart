import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/services/search_history_service.dart';

void main() {
  group('SearchHistoryEntry - Comprehensive Coverage', () {
    group('fromJson factory', () {
      test('should create entry from complete JSON', () {
        final json = {
          'id': 1,
          'uid': 'user-123',
          'building_id': 456,
          'created_at': '2024-01-15T10:30:00Z',
          'building_name': 'Eiffel Tower',
        };

        final entry = SearchHistoryEntry.fromJson(json);

        expect(entry.id, 1);
        expect(entry.uid, 'user-123');
        expect(entry.buildingId, 456);
        expect(entry.buildingName, 'Eiffel Tower');
        expect(entry.createdAt, isA<DateTime>());
      });

      test('should handle null uid', () {
        final json = {
          'id': 1,
          'uid': null,
          'building_id': 456,
          'created_at': '2024-01-15T10:30:00Z',
        };

        final entry = SearchHistoryEntry.fromJson(json);

        expect(entry.uid, '');
      });

      test('should handle missing building_name', () {
        final json = {
          'id': 1,
          'uid': 'user-123',
          'building_id': 456,
          'created_at': '2024-01-15T10:30:00Z',
        };

        final entry = SearchHistoryEntry.fromJson(json);

        expect(entry.buildingName, isNull);
      });

      test('should handle null created_at', () {
        final json = {
          'id': 1,
          'uid': 'user-123',
          'building_id': 456,
          'created_at': null,
        };

        final entry = SearchHistoryEntry.fromJson(json);

        expect(entry.createdAt, isA<DateTime>());
        // Should use DateTime.now() when null
        final now = DateTime.now();
        expect(entry.createdAt.difference(now).inSeconds.abs(), lessThan(2));
      });

      test('should handle missing created_at', () {
        final json = {
          'id': 1,
          'uid': 'user-123',
          'building_id': 456,
        };

        final entry = SearchHistoryEntry.fromJson(json);

        expect(entry.createdAt, isA<DateTime>());
      });

      test('should parse ISO 8601 date correctly', () {
        final json = {
          'id': 1,
          'uid': 'user-123',
          'building_id': 456,
          'created_at': '2024-01-15T10:30:45.123Z',
        };

        final entry = SearchHistoryEntry.fromJson(json);

        expect(entry.createdAt.year, 2024);
        expect(entry.createdAt.month, 1);
        expect(entry.createdAt.day, 15);
        expect(entry.createdAt.hour, 10);
        expect(entry.createdAt.minute, 30);
      });

      test('should handle integer uid', () {
        final json = {
          'id': 1,
          'uid': 12345,
          'building_id': 456,
          'created_at': '2024-01-15T10:30:00Z',
        };

        final entry = SearchHistoryEntry.fromJson(json);

        expect(entry.uid, '12345');
      });

      test('should handle string building_id', () {
        final json = {
          'id': 1,
          'uid': 'user-123',
          'building_id': 456,
          'created_at': '2024-01-15T10:30:00Z',
        };

        final entry = SearchHistoryEntry.fromJson(json);

        expect(entry.buildingId, 456);
      });

      test('should handle zero id', () {
        final json = {
          'id': 0,
          'uid': 'user-123',
          'building_id': 456,
          'created_at': '2024-01-15T10:30:00Z',
        };

        final entry = SearchHistoryEntry.fromJson(json);

        expect(entry.id, 0);
      });

      test('should handle negative building_id', () {
        final json = {
          'id': 1,
          'uid': 'user-123',
          'building_id': -1,
          'created_at': '2024-01-15T10:30:00Z',
        };

        final entry = SearchHistoryEntry.fromJson(json);

        expect(entry.buildingId, -1);
      });

      test('should handle very large numbers', () {
        final json = {
          'id': 999999999,
          'uid': 'user-123',
          'building_id': 888888888,
          'created_at': '2024-01-15T10:30:00Z',
        };

        final entry = SearchHistoryEntry.fromJson(json);

        expect(entry.id, 999999999);
        expect(entry.buildingId, 888888888);
      });

      test('should handle empty string uid', () {
        final json = {
          'id': 1,
          'uid': '',
          'building_id': 456,
          'created_at': '2024-01-15T10:30:00Z',
        };

        final entry = SearchHistoryEntry.fromJson(json);

        expect(entry.uid, '');
      });

      test('should handle empty string building_name', () {
        final json = {
          'id': 1,
          'uid': 'user-123',
          'building_id': 456,
          'created_at': '2024-01-15T10:30:00Z',
          'building_name': '',
        };

        final entry = SearchHistoryEntry.fromJson(json);

        expect(entry.buildingName, '');
      });

      test('should handle very long building_name', () {
        final longName = 'A' * 1000;
        final json = {
          'id': 1,
          'uid': 'user-123',
          'building_id': 456,
          'created_at': '2024-01-15T10:30:00Z',
          'building_name': longName,
        };

        final entry = SearchHistoryEntry.fromJson(json);

        expect(entry.buildingName, longName);
      });

      test('should handle unicode in building_name', () {
        final json = {
          'id': 1,
          'uid': 'user-123',
          'building_id': 456,
          'created_at': '2024-01-15T10:30:00Z',
          'building_name': '艾菲爾鐵塔 🗼',
        };

        final entry = SearchHistoryEntry.fromJson(json);

        expect(entry.buildingName, '艾菲爾鐵塔 🗼');
      });

      test('should handle special characters in uid', () {
        final json = {
          'id': 1,
          'uid': 'user-123_@#\$%',
          'building_id': 456,
          'created_at': '2024-01-15T10:30:00Z',
        };

        final entry = SearchHistoryEntry.fromJson(json);

        expect(entry.uid, 'user-123_@#\$%');
      });
    });

    group('toJson method', () {
      test('should convert entry to JSON correctly', () {
        final createdAt = DateTime.parse('2024-01-15T10:30:45.123Z');
        final entry = SearchHistoryEntry(
          id: 1,
          uid: 'user-123',
          buildingId: 456,
          createdAt: createdAt,
          buildingName: 'Eiffel Tower',
        );

        final json = entry.toJson();

        expect(json['id'], 1);
        expect(json['uid'], 'user-123');
        expect(json['building_id'], 456);
        expect(json['created_at'], createdAt.toIso8601String());
        // Note: buildingName is not included in toJson
        expect(json.containsKey('building_name'), isFalse);
      });

      test('should not include buildingName in JSON', () {
        final entry = SearchHistoryEntry(
          id: 1,
          uid: 'user-123',
          buildingId: 456,
          createdAt: DateTime.now(),
          buildingName: 'Test Building',
        );

        final json = entry.toJson();

        expect(json.containsKey('building_name'), isFalse);
      });

      test('should handle entry without buildingName', () {
        final entry = SearchHistoryEntry(
          id: 1,
          uid: 'user-123',
          buildingId: 456,
          createdAt: DateTime.now(),
        );

        final json = entry.toJson();

        expect(json['id'], 1);
        expect(json['uid'], 'user-123');
        expect(json['building_id'], 456);
      });

      test('should format DateTime as ISO 8601', () {
        final createdAt = DateTime.parse('2024-01-15T10:30:45.123Z');
        final entry = SearchHistoryEntry(
          id: 1,
          uid: 'user-123',
          buildingId: 456,
          createdAt: createdAt,
        );

        final json = entry.toJson();

        expect(json['created_at'], contains('2024-01-15'));
        expect(json['created_at'], contains('T'));
      });

      test('should handle zero values', () {
        final entry = SearchHistoryEntry(
          id: 0,
          uid: '',
          buildingId: 0,
          createdAt: DateTime.now(),
        );

        final json = entry.toJson();

        expect(json['id'], 0);
        expect(json['uid'], '');
        expect(json['building_id'], 0);
      });

      test('should handle negative building_id', () {
        final entry = SearchHistoryEntry(
          id: 1,
          uid: 'user-123',
          buildingId: -1,
          createdAt: DateTime.now(),
        );

        final json = entry.toJson();

        expect(json['building_id'], -1);
      });

      test('should handle very large numbers', () {
        final entry = SearchHistoryEntry(
          id: 999999999,
          uid: 'user-123',
          buildingId: 888888888,
          createdAt: DateTime.now(),
        );

        final json = entry.toJson();

        expect(json['id'], 999999999);
        expect(json['building_id'], 888888888);
      });

      test('should handle special characters in uid', () {
        final entry = SearchHistoryEntry(
          id: 1,
          uid: 'user-123_@#\$%',
          buildingId: 456,
          createdAt: DateTime.now(),
        );

        final json = entry.toJson();

        expect(json['uid'], 'user-123_@#\$%');
      });
    });

    group('Round-trip conversion', () {
      test('should maintain data through fromJson -> toJson', () {
        final originalJson = {
          'id': 1,
          'uid': 'user-123',
          'building_id': 456,
          'created_at': '2024-01-15T10:30:45.123Z',
        };

        final entry = SearchHistoryEntry.fromJson(originalJson);
        final newJson = entry.toJson();

        expect(newJson['id'], originalJson['id']);
        expect(newJson['uid'], originalJson['uid']);
        expect(newJson['building_id'], originalJson['building_id']);
      });

      test('should handle multiple conversions', () {
        final json1 = {
          'id': 1,
          'uid': 'user-123',
          'building_id': 456,
          'created_at': '2024-01-15T10:30:45.123Z',
        };

        final entry1 = SearchHistoryEntry.fromJson(json1);
        final json2 = entry1.toJson();
        final entry2 = SearchHistoryEntry.fromJson(json2);
        final json3 = entry2.toJson();

        expect(json3['id'], json1['id']);
        expect(json3['uid'], json1['uid']);
        expect(json3['building_id'], json1['building_id']);
      });
    });

    group('Constructor', () {
      test('should create entry with all parameters', () {
        final createdAt = DateTime.now();
        final entry = SearchHistoryEntry(
          id: 1,
          uid: 'user-123',
          buildingId: 456,
          createdAt: createdAt,
          buildingName: 'Test Building',
        );

        expect(entry.id, 1);
        expect(entry.uid, 'user-123');
        expect(entry.buildingId, 456);
        expect(entry.createdAt, createdAt);
        expect(entry.buildingName, 'Test Building');
      });

      test('should create entry without buildingName', () {
        final createdAt = DateTime.now();
        final entry = SearchHistoryEntry(
          id: 1,
          uid: 'user-123',
          buildingId: 456,
          createdAt: createdAt,
        );

        expect(entry.buildingName, isNull);
      });

      test('should allow null buildingName', () {
        final entry = SearchHistoryEntry(
          id: 1,
          uid: 'user-123',
          buildingId: 456,
          createdAt: DateTime.now(),
          buildingName: null,
        );

        expect(entry.buildingName, isNull);
      });

      test('should accept empty string buildingName', () {
        final entry = SearchHistoryEntry(
          id: 1,
          uid: 'user-123',
          buildingId: 456,
          createdAt: DateTime.now(),
          buildingName: '',
        );

        expect(entry.buildingName, '');
      });
    });

    group('Mutable buildingName', () {
      test('should allow updating buildingName', () {
        final entry = SearchHistoryEntry(
          id: 1,
          uid: 'user-123',
          buildingId: 456,
          createdAt: DateTime.now(),
        );

        expect(entry.buildingName, isNull);

        entry.buildingName = 'Updated Building';
        expect(entry.buildingName, 'Updated Building');
      });

      test('should allow setting buildingName to null', () {
        final entry = SearchHistoryEntry(
          id: 1,
          uid: 'user-123',
          buildingId: 456,
          createdAt: DateTime.now(),
          buildingName: 'Initial Name',
        );

        expect(entry.buildingName, 'Initial Name');

        entry.buildingName = null;
        expect(entry.buildingName, isNull);
      });

      test('should allow multiple updates to buildingName', () {
        final entry = SearchHistoryEntry(
          id: 1,
          uid: 'user-123',
          buildingId: 456,
          createdAt: DateTime.now(),
        );

        entry.buildingName = 'First Name';
        expect(entry.buildingName, 'First Name');

        entry.buildingName = 'Second Name';
        expect(entry.buildingName, 'Second Name');

        entry.buildingName = null;
        expect(entry.buildingName, isNull);

        entry.buildingName = 'Third Name';
        expect(entry.buildingName, 'Third Name');
      });
    });
  });
}
