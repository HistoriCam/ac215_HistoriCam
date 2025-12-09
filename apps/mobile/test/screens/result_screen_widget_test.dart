import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/screens/result_screen.dart';

void main() {
  group('ResultScreen Widget Tests', () {
    testWidgets('should require either imagePath or buildingId',
        (WidgetTester tester) async {
      // This test verifies the assertion in the constructor
      expect(
        () => ResultScreen(imagePath: null, buildingId: null),
        throwsAssertionError,
      );
    });

    testWidgets('should accept imagePath parameter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: '/test/path.jpg'),
        ),
      );

      // Should show loading state initially
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Analyzing building...'), findsOneWidget);
    });

    testWidgets('should accept buildingId parameter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(buildingId: 123),
        ),
      );

      // Should show loading state initially
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Analyzing building...'), findsOneWidget);
    });

    testWidgets('should accept buildingId with buildingName',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(
            buildingId: 123,
            buildingName: 'Test Building',
          ),
        ),
      );

      // Should show loading state initially
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('should display header with app name',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: '/test/path.jpg'),
        ),
      );

      // Verify header elements
      expect(find.text('HistoriCam'), findsOneWidget);
      expect(find.text('Your Personal Tour Guide'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('should have back button that pops navigation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const ResultScreen(imagePath: '/test/path.jpg'),
                    ),
                  );
                },
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );

      // Navigate to ResultScreen
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      // Verify we're on ResultScreen
      expect(find.text('HistoriCam'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should be back to original screen
      expect(find.text('Go'), findsOneWidget);
    });

    testWidgets('should display loading state correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: '/test/path.jpg'),
        ),
      );

      // Verify loading elements
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Analyzing building...'), findsOneWidget);
      expect(
        find.text('Please wait while we identify the landmark'),
        findsOneWidget,
      );
    });

    testWidgets('should have correct background color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: '/test/path.jpg'),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFF5EFE6));
    });

    testWidgets('should display SafeArea', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: '/test/path.jpg'),
        ),
      );

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('should have Column layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: '/test/path.jpg'),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('header should have correct color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: '/test/path.jpg'),
        ),
      );

      final headerContainer = tester.widget<Container>(
        find.ancestor(
          of: find.text('HistoriCam'),
          matching: find.byType(Container),
        ).first,
      );

      expect(headerContainer.color, const Color(0xFFE63946));
    });

    testWidgets('should display IconButton for back navigation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: '/test/path.jpg'),
        ),
      );

      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('loading indicator should have correct color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: '/test/path.jpg'),
        ),
      );

      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator).first,
      );

      expect(progressIndicator.color, const Color(0xFFE63946));
    });

    testWidgets('should use Scaffold widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: '/test/path.jpg'),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should handle null buildingName with buildingId',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(
            buildingId: 456,
            buildingName: null,
          ),
        ),
      );

      // Should build without error
      expect(find.byType(ResultScreen), findsOneWidget);
    });
  });
}
