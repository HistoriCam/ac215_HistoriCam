// HistoriCam Widget Tests
//
// This file contains basic smoke tests for the HistoriCam app.
// For more comprehensive tests, see:
// - test/app_test.dart - Integration tests for main app
// - test/screens/ - Tests for individual screens
// - test/widgets/ - Tests for reusable widgets
// - test/services/ - Tests for API services
// - test/config/ - Tests for configuration

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/main.dart';
import 'package:historicam/screens/login_screen.dart';

void main() {
  testWidgets('HistoriCam app smoke test', (WidgetTester tester) async {
    // Initialize with empty cameras to avoid permission issues in tests
    cameras = [];

    // Build our app and trigger a frame.
    await tester.pumpWidget(const HistoriCamApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify that the app launches successfully
    // The app may show loading state or login screen depending on auth state
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    // Test the login screen directly
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
}
