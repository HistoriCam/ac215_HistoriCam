// HistoriCam Widget Tests
//
// This file contains basic smoke tests for the HistoriCam app.
// For more comprehensive tests, see:
// - test/app_test.dart - Integration tests for main app
// - test/screens/ - Tests for individual screens
// - test/widgets/ - Tests for reusable widgets
// - test/services/ - Tests for API services
// - test/config/ - Tests for configuration

import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/main.dart';

void main() {
  testWidgets('HistoriCam app smoke test', (WidgetTester tester) async {
    // Initialize with empty cameras to avoid permission issues in tests
    cameras = [];

    // Build our app and trigger a frame.
    await tester.pumpWidget(const HistoriCamApp());
    await tester.pumpAndSettle();

    // Verify that the app launches successfully
    expect(find.text('HistoriCam'), findsOneWidget);
    expect(find.text('Your Personal Tour Guide'), findsOneWidget);

    // Verify the login screen is displayed when not authenticated
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
