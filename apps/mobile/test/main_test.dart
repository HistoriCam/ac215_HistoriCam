import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';
import 'package:historicam/main.dart';

void main() {
  group('HistoriCamApp', () {
    testWidgets('should create app with correct title',
        (WidgetTester tester) async {
      await tester.pumpWidget(const HistoriCamApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.title, equals('HistoriCam'));
    });

    testWidgets('should disable debug banner', (WidgetTester tester) async {
      await tester.pumpWidget(const HistoriCamApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('should use Material3', (WidgetTester tester) async {
      await tester.pumpWidget(const HistoriCamApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.useMaterial3, isTrue);
    });

    testWidgets('should have correct primary color',
        (WidgetTester tester) async {
      await tester.pumpWidget(const HistoriCamApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.primaryColor, const Color(0xFFE63946));
    });

    testWidgets('should have correct scaffold background color',
        (WidgetTester tester) async {
      await tester.pumpWidget(const HistoriCamApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(
          app.theme?.scaffoldBackgroundColor, const Color(0xFF2B2B2B));
    });

    testWidgets('should have theme configured', (WidgetTester tester) async {
      await tester.pumpWidget(const HistoriCamApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme, isNotNull);
      expect(app.theme?.colorScheme, isNotNull);
    });

    testWidgets('should have dark color scheme', (WidgetTester tester) async {
      await tester.pumpWidget(const HistoriCamApp());

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme?.colorScheme.brightness, Brightness.dark);
    });

    testWidgets('should display AuthWrapper as home',
        (WidgetTester tester) async {
      await tester.pumpWidget(const HistoriCamApp());
      await tester.pump();

      expect(find.byType(AuthWrapper), findsOneWidget);
    });
  });

  group('AuthWrapper', () {
    testWidgets('should display loading indicator initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthWrapper(),
        ),
      );

      // Should show loading while auth state is being checked
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should have Scaffold widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthWrapper(),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should use StreamBuilder', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthWrapper(),
        ),
      );

      expect(find.byType(StreamBuilder<dynamic>), findsOneWidget);
    });

    testWidgets('should center loading indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AuthWrapper(),
        ),
      );

      final centerFinder = find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(Center),
      );
      expect(centerFinder, findsOneWidget);
    });
  });

  group('Cameras global variable', () {
    test('should initialize as empty list', () {
      expect(cameras, isA<List<CameraDescription>>());
      expect(cameras, isEmpty);
    });

    test('should be mutable', () {
      final originalLength = cameras.length;
      cameras = [];
      expect(cameras.length, equals(originalLength));
    });
  });
}
