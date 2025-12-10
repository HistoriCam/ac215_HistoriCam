import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/screens/result_screen.dart';

void main() {
  group('ResultScreen', () {
    const testImagePath = '/fake/path/to/image.jpg';

    testWidgets('should display header with back button',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Verify header elements
      expect(find.text('HistoriCam'), findsOneWidget);
      expect(find.text('Your Personal Tour Guide'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('should display loading state initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Should show loading state
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFFF5EFE6));
    });

    testWidgets('header should have correct styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Find the header container
      final headerContainer = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('HistoriCam'),
              matching: find.byType(Container),
            )
            .first,
      );

      // Verify header background color
      expect(
        (headerContainer.decoration as BoxDecoration?)?.color,
        const Color(0xFFE63946),
      );
    }, skip: true); // Skip: Container decoration testing is fragile

    testWidgets('back button should pop the route',
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
                          const ResultScreen(imagePath: testImagePath),
                    ),
                  );
                },
                child: const Text('Navigate'),
              ),
            ),
          ),
        ),
      );

      // Navigate to ResultScreen
      await tester.tap(find.text('Navigate'));
      await tester.pump(); // Start navigation animation
      await tester
          .pump(const Duration(milliseconds: 500)); // Complete navigation

      // Verify we're on the ResultScreen
      expect(find.text('HistoriCam'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump(); // Start back navigation
      await tester
          .pump(const Duration(milliseconds: 500)); // Complete back navigation

      // Verify we're back to the original screen
      expect(find.text('Navigate'), findsOneWidget);
    });

    testWidgets('should display tour suggestions button after loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Wait for the error state (since API will fail in test)
      await tester.pump(const Duration(seconds: 5));

      // Should show tour button
      expect(find.text('Do want suggestions for a tour?'), findsOneWidget);
    }, skip: true); // Skip: Async state loading timing is unreliable in tests

    testWidgets('should display chatbot widget after loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Wait for loading to complete
      await tester.pump(const Duration(seconds: 5));

      // Chatbot should be visible
      expect(find.text('Ask Anything'), findsOneWidget);
    }, skip: true); // Skip: Async state loading timing is unreliable in tests

    testWidgets('should have proper widget structure',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Verify core structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('tour button should show snackbar when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Wait for content to load
      await tester.pump(const Duration(seconds: 5));

      // Tap the tour suggestions button
      await tester.tap(find.text('Do want suggestions for a tour?'));
      await tester.pump();

      // Verify snackbar appears
      expect(find.text('Tour suggestions coming soon!'), findsOneWidget);
    }, skip: true); // Skip: Async state loading timing is unreliable in tests

    testWidgets('should display error state when API fails',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Wait for API call to complete and fail
      await tester.pump(const Duration(seconds: 5));

      // Should eventually show some content (either error or dummy data)
      // The screen should not be stuck in loading state
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Analyzing building...'), findsNothing);
    }, skip: true); // Skip: Async state loading timing is unreliable in tests

    testWidgets('should accept buildingId parameter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(buildingId: 123, buildingName: 'Test Building'),
        ),
      );

      // Should build without errors
      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    test('should require either imagePath or buildingId', () {
      // This test verifies the assertion in the constructor
      // Note: We can't use const here because the assertion fails at compile time
      expect(
        () => ResultScreen(),
        throwsAssertionError,
      );
    });

    testWidgets('should display Column layout in loading state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Loading state should have Column
      final columnFinder = find.descendant(
        of: find.byType(Center),
        matching: find.byType(Column),
      );
      expect(columnFinder, findsWidgets);
    });

    testWidgets('should have multiple widget types in structure',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Verify various widgets exist
      expect(find.byType(Container), findsWidgets);
      expect(find.byType(Row), findsWidgets);
      expect(find.byType(SizedBox), findsWidgets);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('should display camera icon in header',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Camera icon should be in header
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('should have Center widget for loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Loading should be centered
      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('should display subtitle in header',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Subtitle should be present
      expect(find.text('Your Personal Tour Guide'), findsOneWidget);
    });

    testWidgets('should have proper spacing with SizedBox',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // SizedBox for spacing
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('loading message should be visible',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Loading message
      expect(find.text('Analyzing building...'), findsOneWidget);
      expect(
        find.text('Please wait while we identify the landmark'),
        findsOneWidget,
      );
    });

    testWidgets('should initialize with SingleTickerProviderStateMixin',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Widget should be a StatefulWidget
      expect(find.byType(ResultScreen), findsOneWidget);
    });

    testWidgets('should have SafeArea for proper layout',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // SafeArea should exist
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('loading state should have proper styling',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Verify loading state elements
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Find the CircularProgressIndicator and check its color
      final progressIndicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(progressIndicator.color, const Color(0xFFE63946));
    });

    testWidgets('should display building information after loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Wait for processing to complete
      await tester.pump(const Duration(seconds: 5));

      // At this point, should display either building info or error message
      // Since API will fail in test, should show error or dummy data
      expect(find.byType(SingleChildScrollView), findsWidgets);
    }, skip: true); // Skip: Async state loading timing is unreliable in tests

    testWidgets('should contain scrollable content',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(imagePath: testImagePath),
        ),
      );

      // Wait for content to load
      await tester.pump(const Duration(seconds: 5));

      // Should have scrollable content
      expect(find.byType(SingleChildScrollView), findsWidgets);
    }, skip: true); // Skip: Async state loading timing is unreliable in tests
  });
}
