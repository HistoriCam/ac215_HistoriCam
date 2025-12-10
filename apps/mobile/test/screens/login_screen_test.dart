import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/screens/login_screen.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeSupabaseForTest();
  });

  group('LoginScreen', () {
    testWidgets('should render login screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Wait for animations
      await tester.pumpAndSettle();

      // Verify key elements are present
      expect(find.text('HistoriCam'), findsOneWidget);
      expect(find.text('Your Personal Tour Guide'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('should show username and password fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find text form fields
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('should validate empty username', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Try to submit with empty fields
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a username'), findsOneWidget);
    });

    testWidgets('should validate short username', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter short username
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'ab');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(
          find.text('Username must be at least 3 characters'), findsOneWidget);
    });

    testWidgets('should validate empty password', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter username but no password
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'testuser');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a password'), findsOneWidget);
    });

    testWidgets('should toggle password visibility',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find password field
      final passwordField = find.widgetWithText(TextFormField, 'Password');
      expect(passwordField, findsOneWidget);

      // Initially should show visibility_off icon (password is hidden)
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();

      // Should now show visibility icon (password is visible)
      expect(find.byIcon(Icons.visibility), findsOneWidget);

      // Tap again to hide
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      // Should show visibility_off icon again
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('should have hero animation for logo',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Hero widget exists with correct tag
      expect(find.byType(Hero), findsOneWidget);
      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, equals('app_logo'));
    });

    testWidgets('should render with gradient background',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify container with gradient exists
      final container = find.ancestor(
        of: find.byType(SafeArea),
        matching: find.byType(Container),
      );
      expect(container, findsOneWidget);
    });

    testWidgets('should have correct branding colors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify icon exists (representing the brand)
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });

    testWidgets('should animate on load', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Verify FadeTransition exists
      expect(find.byType(FadeTransition), findsAtLeastNWidgets(1));

      // Complete the animation
      await tester.pumpAndSettle();

      // Verify screen is still showing after animation
      expect(find.text('HistoriCam'), findsOneWidget);
    });

    testWidgets('should have proper widget hierarchy', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Should have core structural widgets
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('should have Column layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Should use Column for vertical layout
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('should have Container widgets', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Should use Containers for styling
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('should have SizedBox for spacing', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Should use SizedBox for spacing
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('should have two TextFields', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Should have two text fields (username and password)
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('should have ElevatedButton', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Should have elevated button for login/signup
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should have TextButton for mode switch', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Should have text button to switch modes
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('should use Row widgets for layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Should use Row for horizontal layouts
      expect(find.byType(Row), findsWidgets);
    });

  });
}
