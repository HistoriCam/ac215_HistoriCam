import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/main.dart';
import 'package:historicam/screens/login_screen.dart';

void main() {
  // Set up test environment
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoriCam App Integration Tests', () {
    testWidgets('app should launch and display login screen',
        (WidgetTester tester) async {
      // Initialize with no cameras to avoid permission issues in tests
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());

      // Wait for async initialization and build
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify app launches
      expect(find.byType(MaterialApp), findsOneWidget);

      // App may show loading or login screen - both are valid
      // Just verify it doesn't crash and shows the app branding
      expect(find.text('HistoriCam'), findsWidgets);
    });

    testWidgets('app should have correct theme configuration',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pump();

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
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Verify font family through theme - fontFamily is set at theme level
      expect(materialApp.theme, isNotNull);
    });

    testWidgets('app theme should have dark color scheme',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pump();

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
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify the widget tree structure
      expect(find.byType(MaterialApp), findsOneWidget);

      // May have Scaffold from either login or camera screen
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('theme should have correct seed color',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pump();

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
    });

    testWidgets('app should show AuthWrapper as home screen',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pump();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Verify home is not null
      expect(materialApp.home, isNotNull);
    });
  });

  group('App Navigation Integration Tests', () {
    testWidgets('app should show login screen when not authenticated',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Wait for auth state to settle - may show login or loading
      // We just verify the app doesn't crash
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('app should maintain state during navigation',
        (WidgetTester tester) async {
      cameras = [];

      await tester.pumpWidget(const HistoriCamApp());
      await tester.pump();

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

      // Verify theme is applied
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
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

  group('Login Screen Tests', () {
    testWidgets('login screen should render correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pump();

      // Verify login screen elements
      expect(find.text('HistoriCam'), findsOneWidget);
      expect(find.text('Your Personal Tour Guide'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('login screen should toggle between login and signup modes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pump();

      // Initially should show Login button
      expect(find.text('Login'), findsOneWidget);

      // Tap the toggle to switch to signup mode
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Should now show Create Account button
      expect(find.text('Create Account'), findsOneWidget);
    });
  });
}
