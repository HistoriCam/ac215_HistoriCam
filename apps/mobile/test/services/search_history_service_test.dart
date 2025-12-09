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

      expect(entry.createdAt.isAfter(before.subtract(Duration(seconds: 1))),
          isTrue);
      expect(entry.createdAt.isBefore(after.add(Duration(seconds: 1))), isTrue);
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
  });
}
