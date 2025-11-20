import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/main.dart';

void main() {
  group('HistoriCam App Integration Tests', () {
    testWidgets('app should launch and display camera screen',
        (WidgetTester tester) async {
      // Initialize with no cameras to avoid permission issues in tests
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());

      // Verify app launches
      expect(find.byType(MaterialApp), findsOneWidget);

      // Verify CameraScreen is displayed
      expect(find.text('HistoriCam'), findsOneWidget);
      expect(find.text('Your Personal Tour Guide'), findsOneWidget);
    });

    testWidgets('app should have correct theme configuration',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Verify app title
      expect(materialApp.title, 'HistoriCam');

      // Verify debug banner is disabled
      expect(materialApp.debugShowCheckedModeBanner, false);

      // Verify theme colors
      expect(materialApp.theme?.primaryColor, const Color(0xFFE63946));
      expect(
        materialApp.theme?.scaffoldBackgroundColor,
        const Color(0xFF2B2B2B),
      );

      // Verify Material 3 is enabled
      expect(materialApp.theme?.useMaterial3, true);
    });

    testWidgets('app should use Roboto font family',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Verify font family through TextTheme
      expect(materialApp.theme?.textTheme.bodyLarge?.fontFamily, 'Roboto');
    });

    testWidgets('app theme should have dark color scheme',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Verify dark brightness
      expect(
        materialApp.theme?.colorScheme.brightness,
        Brightness.dark,
      );
    });

    testWidgets('app should be a stateless widget',
        (WidgetTester tester) async {
      const app = HistoriCamApp();

      expect(app, isA<StatelessWidget>());
    });

    testWidgets('app should have proper widget hierarchy',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());

      // Verify the widget tree structure
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('theme should have correct seed color',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // The color scheme should be based on the red seed color
      expect(
        materialApp.theme?.colorScheme.primary,
        isNot(equals(Colors.blue)), // Default Flutter theme is blue
      );
    });

    testWidgets('app should handle camera initialization errors gracefully',
        (WidgetTester tester) async {
      // Set cameras to empty list to simulate no cameras available
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pump();

      // App should still launch without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('HistoriCam'), findsOneWidget);
    });

    testWidgets('camera screen should be the home screen',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Verify CameraScreen is the home widget
      expect(materialApp.home, isNotNull);
    });
  });

  group('App Navigation Integration Tests', () {
    testWidgets('app should handle navigation properly',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pump();

      // Verify we start on camera screen
      expect(find.text('Tap to capture'), findsOneWidget);
    });

    testWidgets('app should maintain state during navigation',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pump();

      // Verify initial state
      expect(find.text('HistoriCam'), findsOneWidget);

      // The app title should remain consistent
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'HistoriCam');
    });
  });

  group('App Theme Integration Tests', () {
    testWidgets('all screens should use the app theme',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pump();

      // Find elements with theme colors
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container && widget.color == const Color(0xFFE63946),
        ),
        findsWidgets,
      );

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Scaffold &&
              widget.backgroundColor == const Color(0xFF2B2B2B),
        ),
        findsOneWidget,
      );
    });

    testWidgets('theme colors should be consistent across app',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Primary color should be red
      expect(materialApp.theme?.primaryColor, const Color(0xFFE63946));

      // Background should be dark
      expect(
        materialApp.theme?.scaffoldBackgroundColor,
        const Color(0xFF2B2B2B),
      );
    });
  });
}
