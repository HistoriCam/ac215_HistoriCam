import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/services/search_history_service.dart';

void main() {
  group('SearchHistoryEntry', () {
    test('should create entry with all fields', () {
      final entry = SearchHistoryEntry(
        id: 1,
        uid: 'user123',
        buildingId: 42,
        createdAt: DateTime.parse('2024-01-01T10:00:00Z'),
        buildingName: 'Test Building',
      );

      expect(entry.id, 1);
      expect(entry.uid, 'user123');
      expect(entry.buildingId, 42);
      expect(entry.buildingName, 'Test Building');
    });

    test('buildingName should be nullable', () {
      final entry = SearchHistoryEntry(
        id: 1,
        uid: 'user123',
        buildingId: 42,
        createdAt: DateTime.now(),
      );

      expect(entry.buildingName, isNull);
    });

    test('should set buildingName after creation', () {
      final entry = SearchHistoryEntry(
        id: 1,
        uid: 'user123',
        buildingId: 42,
        createdAt: DateTime.now(),
      );

      entry.buildingName = 'Updated Name';
      expect(entry.buildingName, 'Updated Name');
    });

    test('createdAt should store DateTime correctly', () {
      final now = DateTime.now();
      final entry = SearchHistoryEntry(
        id: 1,
        uid: 'user123',
        buildingId: 42,
        createdAt: now,
      );

      expect(entry.createdAt, equals(now));
    });

    test('should handle different buildingId values', () {
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

    test('should handle different uid formats', () {
      final entry1 = SearchHistoryEntry(
        id: 1,
        uid: 'uuid-1234-5678',
        buildingId: 42,
        createdAt: DateTime.now(),
      );

      final entry2 = SearchHistoryEntry(
        id: 2,
        uid: '',
        buildingId: 42,
        createdAt: DateTime.now(),
      );

      expect(entry1.uid, 'uuid-1234-5678');
      expect(entry2.uid, '');
    });

    test('should handle very old dates', () {
      final oldDate = DateTime.parse('1900-01-01T00:00:00Z');
      final entry = SearchHistoryEntry(
        id: 1,
        uid: 'user123',
        buildingId: 42,
        createdAt: oldDate,
      );

      expect(entry.createdAt.year, 1900);
    });

    test('should handle future dates', () {
      final futureDate = DateTime.parse('2100-12-31T23:59:59Z');
      final entry = SearchHistoryEntry(
        id: 1,
        uid: 'user123',
        buildingId: 42,
        createdAt: futureDate,
      );

      expect(entry.createdAt.year, 2100);
    });
  });
}
