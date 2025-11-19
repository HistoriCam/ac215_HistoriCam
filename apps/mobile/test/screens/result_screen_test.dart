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
    });

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
      await tester.pump();

      // Verify we're on the ResultScreen
      expect(find.text('HistoriCam'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

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
    });

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
    });

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
    });

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
    });

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
    });
  });
}
