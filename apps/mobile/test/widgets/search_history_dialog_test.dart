import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/widgets/search_history_dialog.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeSupabaseForTest();
  });

  group('SearchHistoryDialog', () {
    testWidgets('should display dialog UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchHistoryDialog(
              onSearchSelected: (buildingId, buildingName) {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify header elements
      expect(find.text('Search History'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should close dialog when close button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => SearchHistoryDialog(
                        onSearchSelected: (id, name) {},
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Show the dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Search History'), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Search History'), findsNothing);
    });

    testWidgets('should display loading indicator initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchHistoryDialog(
              onSearchSelected: (id, name) {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display empty state when no history',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchHistoryDialog(
              onSearchSelected: (id, name) {},
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Verify empty state is shown
      expect(find.text('No Previous Searches'), findsOneWidget);
      expect(find.text('Your search history will appear here'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
    });

    testWidgets('should have proper dialog styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchHistoryDialog(
              onSearchSelected: (id, name) {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify Dialog widget exists
      expect(find.byType(Dialog), findsOneWidget);

      // Verify divider exists
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('should display all required widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchHistoryDialog(
              onSearchSelected: (id, name) {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify container structure
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('should have close icon button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchHistoryDialog(
              onSearchSelected: (id, name) {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify close button exists
      final closeButton = find.byIcon(Icons.close);
      expect(closeButton, findsOneWidget);

      // Verify it's in an IconButton
      final iconButton = find.ancestor(
        of: closeButton,
        matching: find.byType(IconButton),
      );
      expect(iconButton, findsOneWidget);
    });
  });
}
