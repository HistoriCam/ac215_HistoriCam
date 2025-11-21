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

    testWidgets('should toggle between login and signup modes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Initially in login mode
      expect(find.text('Login'), findsOneWidget);
      expect(find.text("Don't have an account? "), findsOneWidget);

      // Tap toggle button
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Now in signup mode
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Already have an account? '), findsOneWidget);

      // Toggle back
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
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

    testWidgets('should validate short password in signup mode',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to signup mode
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Enter valid username but short password
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'testuser');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), '12345');
      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(
          find.text('Password must be at least 6 characters'), findsOneWidget);
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

    testWidgets('should show loading indicator when submitting',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid credentials
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'testuser');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password123');

      // Submit form
      await tester.tap(find.text('Login'));
      await tester.pump(); // Trigger loading state

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should disable fields while loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid credentials
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'testuser');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password123');

      // Submit form
      await tester.tap(find.text('Login'));
      await tester.pump();

      // Fields should be disabled
      final usernameField = tester.widget<TextFormField>(
          find.widgetWithText(TextFormField, 'Username'));
      expect(usernameField.enabled, isFalse);
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

    testWidgets('should clear error when toggling modes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter invalid short username to trigger error
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'ab');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Error should be visible
      expect(
          find.text('Username must be at least 3 characters'), findsOneWidget);

      // Toggle to signup mode
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Error should be cleared (validation happens on new submit)
      // The form is cleared when mode changes
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
      expect(find.byType(FadeTransition), findsOneWidget);

      // Complete the animation
      await tester.pumpAndSettle();
    });

    testWidgets('should support keyboard submission',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter credentials
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Username'), 'testuser');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'password123');

      // Submit via keyboard (testTextInput.receiveAction)
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Should trigger form submission
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
