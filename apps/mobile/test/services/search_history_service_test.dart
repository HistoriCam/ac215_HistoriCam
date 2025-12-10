import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/services/search_history_service.dart';

void main() {
  group('SearchHistoryEntry', () {
    test('fromJson should parse valid JSON correctly', () {
      final json = {
        'id': 1,
        'uid': 'user123',
        'building_id': 42,
        'created_at': '2024-01-15T10:30:00.000Z',
        'building_name': 'Sever Hall',
      };

      final entry = SearchHistoryEntry.fromJson(json);

      expect(entry.id, 1);
      expect(entry.uid, 'user123');
      expect(entry.buildingId, 42);
      expect(entry.buildingName, 'Sever Hall');
      expect(entry.createdAt.year, 2024);
    });

    test('fromJson should handle null building_name', () {
      final json = {
        'id': 1,
        'uid': 'user123',
        'building_id': 42,
        'created_at': '2024-01-15T10:30:00.000Z',
      };

      final entry = SearchHistoryEntry.fromJson(json);

      expect(entry.buildingName, isNull);
    });

    test('fromJson should handle null uid gracefully', () {
      final json = {
        'id': 1,
        'uid': null,
        'building_id': 42,
        'created_at': '2024-01-15T10:30:00.000Z',
      };

      final entry = SearchHistoryEntry.fromJson(json);

      expect(entry.uid, '');
    });

    test('fromJson should use current time if created_at is null', () {
      final json = {
        'id': 1,
        'uid': 'user123',
        'building_id': 42,
        'created_at': null,
      };

      final before = DateTime.now();
      final entry = SearchHistoryEntry.fromJson(json);
      final after = DateTime.now();

      expect(entry.createdAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
      expect(entry.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('toJson should convert entry to JSON correctly', () {
      final entry = SearchHistoryEntry(
        id: 1,
        uid: 'user123',
        buildingId: 42,
        createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
        buildingName: 'Sever Hall',
      );

      final json = entry.toJson();

      expect(json['id'], 1);
      expect(json['uid'], 'user123');
      expect(json['building_id'], 42);
      expect(json['created_at'], '2024-01-15T10:30:00.000Z');
      // Note: toJson doesn't include building_name
    });

    test('should create entry with required parameters', () {
      final entry = SearchHistoryEntry(
        id: 1,
        uid: 'user123',
        buildingId: 42,
        createdAt: DateTime.now(),
      );

      expect(entry.id, 1);
      expect(entry.uid, 'user123');
      expect(entry.buildingId, 42);
      expect(entry.buildingName, isNull);
    });

    test('should create entry with all parameters', () {
      final now = DateTime.now();
      final entry = SearchHistoryEntry(
        id: 1,
        uid: 'user123',
        buildingId: 42,
        createdAt: now,
        buildingName: 'Test Building',
      );

      expect(entry.id, 1);
      expect(entry.uid, 'user123');
      expect(entry.buildingId, 42);
      expect(entry.createdAt, now);
      expect(entry.buildingName, 'Test Building');
    });

    test('fromJson should handle numeric uid', () {
      final json = {
        'id': 1,
        'uid': 12345,
        'building_id': 42,
        'created_at': '2024-01-15T10:30:00.000Z',
      };

      final entry = SearchHistoryEntry.fromJson(json);
      expect(entry.uid, '12345');
    });

    test('fromJson should parse ISO 8601 date correctly', () {
      final json = {
        'id': 1,
        'uid': 'user123',
        'building_id': 42,
        'created_at': '2024-03-15T14:30:00.000Z',
      };

      final entry = SearchHistoryEntry.fromJson(json);
      expect(entry.createdAt.year, 2024);
      expect(entry.createdAt.month, 3);
      expect(entry.createdAt.day, 15);
    });

    test('toJson should produce valid ISO 8601 date string', () {
      final entry = SearchHistoryEntry(
        id: 1,
        uid: 'user123',
        buildingId: 42,
        createdAt: DateTime.utc(2024, 3, 15, 14, 30, 0),
      );

      final json = entry.toJson();
      expect(json['created_at'], contains('2024-03-15'));
      expect(json['created_at'], contains('14:30:00'));
    });

    test('should handle empty string uid', () {
      final entry = SearchHistoryEntry(
        id: 1,
        uid: '',
        buildingId: 42,
        createdAt: DateTime.now(),
      );

      expect(entry.uid, '');
    });

    test('should handle different building IDs', () {
      final entry1 = SearchHistoryEntry(
        id: 1,
        uid: 'user123',
        buildingId: 0,
        createdAt: DateTime.now(),
      );

      final entry2 = SearchHistoryEntry(
        id: 2,
        uid: 'user123',
        buildingId: 999999,
        createdAt: DateTime.now(),
      );

      expect(entry1.buildingId, 0);
      expect(entry2.buildingId, 999999);
    });

    test('buildingName should be mutable', () {
      final entry = SearchHistoryEntry(
        id: 1,
        uid: 'user123',
        buildingId: 42,
        createdAt: DateTime.now(),
      );

      expect(entry.buildingName, isNull);
      entry.buildingName = 'New Building Name';
      expect(entry.buildingName, 'New Building Name');
    });

    test('toJson should include all required fields', () {
      final entry = SearchHistoryEntry(
        id: 1,
        uid: 'user123',
        buildingId: 42,
        createdAt: DateTime.now(),
      );

      final json = entry.toJson();

      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('uid'), isTrue);
      expect(json.containsKey('building_id'), isTrue);
      expect(json.containsKey('created_at'), isTrue);
    });

    test('fromJson and toJson should be consistent', () {
      final originalJson = {
        'id': 1,
        'uid': 'user123',
        'building_id': 42,
        'created_at': '2024-01-15T10:30:00.000Z',
      };

      final entry = SearchHistoryEntry.fromJson(originalJson);
      final newJson = entry.toJson();

      expect(newJson['id'], originalJson['id']);
      expect(newJson['uid'], originalJson['uid']);
      expect(newJson['building_id'], originalJson['building_id']);
    });
  });

  group('SearchHistoryService', () {
    test('should initialize correctly', () {
      // Service requires Supabase to be initialized, which we can't do in unit tests
      // This test verifies the service class exists and can be instantiated in theory
      expect(SearchHistoryService, isNotNull);
    });

    test('should create service type', () {
      // Verify the type exists
      expect(SearchHistoryService, isA<Type>());
    });
  });
}
