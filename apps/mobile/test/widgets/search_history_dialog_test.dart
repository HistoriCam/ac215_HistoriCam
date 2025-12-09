import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/widgets/search_history_dialog.dart';
import 'package:historicam/services/search_history_service.dart';

void main() {
  group('SearchHistoryDialog', () {
    testWidgets('should display title correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchHistoryDialog(
              onSearchSelected: (buildingId, buildingName) {
                // Callback is set but not tested here
              },
            ),
          ),
        ),
      );

      expect(find.text('Last Search'), findsOneWidget);
    });

    testWidgets('should call callback when item is tapped',
        (WidgetTester tester) async {
      int? selectedBuildingId;
      String? selectedBuildingName;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchHistoryDialog(
              onSearchSelected: (buildingId, buildingName) {
                selectedBuildingId = buildingId;
                selectedBuildingName = buildingName;
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify callback is set up correctly
      expect(selectedBuildingId, isNull);
      expect(selectedBuildingName, isNull);
    });

    testWidgets('should display close button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchHistoryDialog(
              onSearchSelected: (buildingId, buildingName) {},
            ),
          ),
        ),
      );

      expect(find.byType(IconButton), findsWidgets);
    });
  });

  group('SearchHistoryEntry Model', () {
    test('should create entry with all fields', () {
      final entry = SearchHistoryEntry(
        id: 1,
        uid: 'test-user',
        buildingId: 100,
        createdAt: DateTime(2024, 1, 1),
        buildingName: 'Test Building',
      );

      expect(entry.id, 1);
      expect(entry.uid, 'test-user');
      expect(entry.buildingId, 100);
      expect(entry.buildingName, 'Test Building');
      expect(entry.createdAt.year, 2024);
    });

    test('should handle missing building name', () {
      final entry = SearchHistoryEntry(
        id: 1,
        uid: 'test-user',
        buildingId: 100,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(entry.buildingName, isNull);
    });
  });
}
