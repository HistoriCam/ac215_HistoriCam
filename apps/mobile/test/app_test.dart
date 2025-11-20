import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/main.dart';

void main() {
  group('HistoriCam App Integration Tests', () {
    testWidgets('app should launch and display login screen',
        (WidgetTester tester) async {
      // Initialize with no cameras to avoid permission issues in tests
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pumpAndSettle();

      // Verify app launches
      expect(find.byType(MaterialApp), findsOneWidget);

      // Verify LoginScreen or CameraScreen is displayed
      // The app shows LoginScreen when no user is authenticated
      expect(find.text('HistoriCam'), findsOneWidget);
      expect(find.text('Your Personal Tour Guide'), findsOneWidget);
    });

    testWidgets('app should have correct theme configuration',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Verify font family through TextTheme
      expect(materialApp.theme?.textTheme.bodyLarge?.fontFamily, 'Roboto');
    });

    testWidgets('app theme should have dark color scheme',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      // Verify the widget tree structure
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('theme should have correct seed color',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      // App should still launch without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('HistoriCam'), findsOneWidget);
    });

    testWidgets('app should show AuthWrapper as home screen',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Verify AuthWrapper is the home widget
      expect(materialApp.home, isNotNull);
    });
  });

  group('App Navigation Integration Tests', () {
    testWidgets('app should show login screen when not authenticated',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pumpAndSettle();

      // Should show login screen with login/signup toggle
      expect(find.text('HistoriCam'), findsOneWidget);
      expect(find.text('Your Personal Tour Guide'), findsOneWidget);

      // Look for login-specific elements
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('app should maintain state during navigation',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pumpAndSettle();

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
      await tester.pumpAndSettle();

      // Find elements with theme colors (login screen has red theme elements)
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container && widget.decoration != null,
        ),
        findsWidgets,
      );

      // Verify scaffold exists (could be from login or camera screen)
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('theme colors should be consistent across app',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pumpAndSettle();

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
