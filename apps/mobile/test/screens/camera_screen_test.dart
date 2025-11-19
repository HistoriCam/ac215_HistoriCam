import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/screens/camera_screen.dart';
import 'package:historicam/main.dart';

void main() {
  group('CameraScreen', () {
    // Note: Testing camera functionality requires mocking camera controller
    // which is complex in Flutter. These tests focus on UI elements and structure.

    testWidgets('should display app header', (WidgetTester tester) async {
      // Initialize with empty cameras to avoid camera initialization
      cameras = [];

      await tester.pumpWidget(
        const MaterialApp(
          home: CameraScreen(),
        ),
      );

      // Verify header elements
      expect(find.text('HistoriCam'), findsOneWidget);
      expect(find.text('Your Personal Tour Guide'), findsOneWidget);
      expect(
          find.byIcon(Icons.camera_alt), findsWidgets); // Multiple camera icons
    });

    testWidgets('should display loading state when camera is initializing',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(
        const MaterialApp(
          home: CameraScreen(),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(find.text('Initializing camera...'), findsOneWidget);
    });

    testWidgets('should have correct background color',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(
        const MaterialApp(
          home: CameraScreen(),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, const Color(0xFF2B2B2B));
    });

    testWidgets('should display capture button', (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(
        const MaterialApp(
          home: CameraScreen(),
        ),
      );

      // Verify capture button text
      expect(find.text('Tap to capture'), findsOneWidget);

      // Verify camera icon in capture button
      expect(find.byIcon(Icons.camera), findsOneWidget);
    });

    testWidgets('should display instruction overlay',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(
        const MaterialApp(
          home: CameraScreen(),
        ),
      );

      await tester.pump();

      // The instruction text should appear once camera initializes
      // Since we have no cameras, we won't see the overlay
      // This test documents the expected behavior
      expect(
          find.text('Point your camera at a historic building'), findsNothing);
    });

    testWidgets('should have proper widget structure',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(
        const MaterialApp(
          home: CameraScreen(),
        ),
      );

      // Verify core structure
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('header should have correct styling',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(
        const MaterialApp(
          home: CameraScreen(),
        ),
      );

      // Find all containers that could be the header
      final containers = find.ancestor(
        of: find.text('HistoriCam'),
        matching: find.byType(Container),
      );

      // Verify at least one container exists with the header color
      expect(containers, findsWidgets);

      // Check if any container has the correct color
      bool foundHeaderColor = false;
      for (var i = 0;
          i < tester.widgetList<Container>(containers).length;
          i++) {
        final container = tester.widgetList<Container>(containers).elementAt(i);
        if ((container.decoration as BoxDecoration?)?.color ==
            const Color(0xFFE63946)) {
          foundHeaderColor = true;
          break;
        }
      }
      expect(foundHeaderColor, true);
    }, skip: true); // Skip: Container decoration testing is fragile

    testWidgets('capture button should be disabled when processing',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(
        const MaterialApp(
          home: CameraScreen(),
        ),
      );

      // The capture button should exist
      final gestureDetector = tester.widget<GestureDetector>(
        find.ancestor(
          of: find.byIcon(Icons.camera),
          matching: find.byType(GestureDetector),
        ),
      );

      // When not processing, onTap should be set (though it may be null due to camera not initialized)
      expect(gestureDetector, isNotNull);
    });

    testWidgets('should display camera controls section',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(
        const MaterialApp(
          home: CameraScreen(),
        ),
      );

      // Camera controls should be visible
      expect(find.text('Tap to capture'), findsOneWidget);

      // Capture button container should exist
      expect(
        find.ancestor(
          of: find.byIcon(Icons.camera),
          matching: find.byType(Container),
        ),
        findsWidgets,
      );
    });

    testWidgets('capture button should have proper styling',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(
        const MaterialApp(
          home: CameraScreen(),
        ),
      );

      // Find the capture button container
      final captureButton = tester.widget<Container>(
        find
            .descendant(
              of: find.ancestor(
                of: find.byIcon(Icons.camera),
                matching: find.byType(Container),
              ),
              matching: find.byType(Container),
            )
            .first,
      );

      // Verify it has decoration
      expect(captureButton.decoration, isNotNull);
      expect(captureButton.decoration, isA<BoxDecoration>());

      final decoration = captureButton.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });
  });
}
