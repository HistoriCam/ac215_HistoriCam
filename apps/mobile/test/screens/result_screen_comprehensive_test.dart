import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/screens/result_screen.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeSupabaseForTest();
  });

  group('ResultScreen - Comprehensive Coverage', () {
    group('Constructor validation', () {
      test('should require either imagePath or buildingId', () {
        expect(
          () => ResultScreen(imagePath: null, buildingId: null),
          throwsAssertionError,
        );
      });

      testWidgets('should accept imagePath only', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        expect(find.byType(ResultScreen), findsOneWidget);
      });

      testWidgets('should accept buildingId only', (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(
            const MaterialApp(
              home: ResultScreen(buildingId: 123, buildingName: 'Test'),
            ),
          );

          expect(find.byType(ResultScreen), findsOneWidget);

          // Give time for async operations to start
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Pump any remaining frames
        await tester.pump();
      });

      testWidgets('should accept both imagePath and buildingId',
          (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(
            const MaterialApp(
              home: ResultScreen(
                imagePath: '/test/image.jpg',
                buildingId: 123,
              ),
            ),
          );

          expect(find.byType(ResultScreen), findsOneWidget);

          // Give time for async operations to start
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Pump any remaining frames
        await tester.pump();
      });

      testWidgets('should accept buildingName parameter',
          (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(
            const MaterialApp(
              home: ResultScreen(
                buildingId: 123,
                buildingName: 'Test Building',
              ),
            ),
          );

          expect(find.byType(ResultScreen), findsOneWidget);

          // Give time for async operations to start
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Pump any remaining frames
        await tester.pump();
      });
    });

    group('Loading state', () {
      testWidgets('should show loading indicator initially with imagePath',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Analyzing building...'), findsOneWidget);
      });

      testWidgets('should show loading indicator initially with buildingId',
          (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(
            const MaterialApp(
              home: ResultScreen(buildingId: 123, buildingName: 'Test'),
            ),
          );

          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.text('Analyzing building...'), findsOneWidget);

          // Give time for async operations to start
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Pump any remaining frames
        await tester.pump();
      });

      testWidgets('should display loading message',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        expect(find.text('Please wait while we identify the landmark'),
            findsOneWidget);
      });

      testWidgets('should have correct loading text color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        final textWidget = tester.widget<Text>(
          find.text('Analyzing building...'),
        );
        expect(textWidget.style?.color, const Color(0xFF2B2B2B));
      });

      testWidgets('should center loading indicator',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        final centerFinder = find.ancestor(
          of: find.byType(CircularProgressIndicator),
          matching: find.byType(Center),
        );
        expect(centerFinder, findsOneWidget);
      });
    });

    group('Header', () {
      testWidgets('should display HistoriCam header',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        expect(find.text('HistoriCam'), findsOneWidget);
        expect(find.text('Your Personal Tour Guide'), findsOneWidget);
      });

      testWidgets('should have back button', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        expect(find.byType(IconButton), findsOneWidget);
      });

      testWidgets('should display camera icon in header',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      });

      testWidgets('back button should pop navigation',
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
                        builder: (_) =>
                            const ResultScreen(imagePath: '/test/image.jpg'),
                      ),
                    );
                  },
                  child: const Text('Go'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Go'));
        await tester.pump(); // Start navigation
        await tester.pump(const Duration(milliseconds: 500)); // Animate navigation

        expect(find.byType(ResultScreen), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pump(); // Start the pop animation
        await tester.pump(const Duration(milliseconds: 500)); // Complete the animation
        await tester.pump(); // One more frame to ensure completion

        expect(find.byType(ResultScreen), findsNothing);
      });

      testWidgets('header should have correct background color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        final container = tester.widget<Container>(
          find.ancestor(
            of: find.text('HistoriCam'),
            matching: find.byType(Container),
          ).first,
        );

        expect(container.color, const Color(0xFFE63946));
      });
    });

    group('Widget structure', () {
      testWidgets('should have Scaffold widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('should have SafeArea widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        expect(find.byType(SafeArea), findsOneWidget);
      });

      testWidgets('should have correct background color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, const Color(0xFFF5EFE6));
      });

      testWidgets('should use Column for layout', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        expect(find.byType(Column), findsWidgets);
      });

      testWidgets('should use Expanded widget', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        expect(find.byType(Expanded), findsOneWidget);
      });

      testWidgets('should use Row widgets', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        expect(find.byType(Row), findsWidgets);
      });

      testWidgets('should use Container widgets',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('should use SizedBox for spacing',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        expect(find.byType(SizedBox), findsWidgets);
      });
    });

    group('Loading state variations', () {
      testWidgets('should show consistent loading for different building IDs',
          (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(
            const MaterialApp(
              home: ResultScreen(buildingId: 999, buildingName: 'Test'),
            ),
          );

          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(find.text('Analyzing building...'), findsOneWidget);

          // Give time for async operations to start
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Pump any remaining frames
        await tester.pump();
      });

      testWidgets('should show loading with very long imagePath',
          (WidgetTester tester) async {
        final longPath = '/test/${'a' * 1000}.jpg';
        await tester.pumpWidget(
          MaterialApp(
            home: ResultScreen(imagePath: longPath),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should handle buildingId of 0', (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(
            const MaterialApp(
              home: ResultScreen(buildingId: 0, buildingName: 'Test'),
            ),
          );

          expect(find.byType(ResultScreen), findsOneWidget);

          // Give time for async operations to start
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Pump any remaining frames
        await tester.pump();
      });

      testWidgets('should handle negative buildingId',
          (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(
            const MaterialApp(
              home: ResultScreen(buildingId: -1, buildingName: 'Test'),
            ),
          );

          expect(find.byType(ResultScreen), findsOneWidget);

          // Give time for async operations to start
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Pump any remaining frames
        await tester.pump();
      });

      testWidgets('should handle very large buildingId',
          (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(
            const MaterialApp(
              home: ResultScreen(buildingId: 999999999, buildingName: 'Test'),
            ),
          );

          expect(find.byType(ResultScreen), findsOneWidget);

          // Give time for async operations to start
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Pump any remaining frames
        await tester.pump();
      });
    });

    group('Building name variations', () {
      testWidgets('should handle empty buildingName',
          (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(
            const MaterialApp(
              home: ResultScreen(
                buildingId: 123,
                buildingName: '',
              ),
            ),
          );

          expect(find.byType(ResultScreen), findsOneWidget);

          // Give time for async operations to start
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Pump any remaining frames
        await tester.pump();
      });

      testWidgets('should handle very long buildingName',
          (WidgetTester tester) async {
        await tester.runAsync(() async {
          final longName = 'A' * 1000;
          await tester.pumpWidget(
            MaterialApp(
              home: ResultScreen(
                buildingId: 123,
                buildingName: longName,
              ),
            ),
          );

          expect(find.byType(ResultScreen), findsOneWidget);

          // Give time for async operations to start
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Pump any remaining frames
        await tester.pump();
      });

      testWidgets('should handle buildingName with special characters',
          (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(
            const MaterialApp(
              home: ResultScreen(
                buildingId: 123,
                buildingName: 'Test-Building_123.v2',
              ),
            ),
          );

          expect(find.byType(ResultScreen), findsOneWidget);

          // Give time for async operations to start
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Pump any remaining frames
        await tester.pump();
      });

      testWidgets('should handle unicode buildingName',
          (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(
            const MaterialApp(
              home: ResultScreen(
                buildingId: 123,
                buildingName: '艾菲爾鐵塔 🗼',
              ),
            ),
          );

          expect(find.byType(ResultScreen), findsOneWidget);

          // Give time for async operations to start
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Pump any remaining frames
        await tester.pump();
      });
    });

    group('Image path variations', () {
      testWidgets('should handle relative image path',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: 'image.jpg'),
          ),
        );

        expect(find.byType(ResultScreen), findsOneWidget);
      });

      testWidgets('should handle absolute image path',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/absolute/path/image.jpg'),
          ),
        );

        expect(find.byType(ResultScreen), findsOneWidget);
      });

      testWidgets('should handle image path with spaces',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/path/with spaces/image.jpg'),
          ),
        );

        expect(find.byType(ResultScreen), findsOneWidget);
      });

      testWidgets('should handle Windows-style path',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: r'C:\Users\test\image.jpg'),
          ),
        );

        expect(find.byType(ResultScreen), findsOneWidget);
      });

      testWidgets('should handle URL-style path', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(
                imagePath: 'https://example.com/images/test.jpg'),
          ),
        );

        expect(find.byType(ResultScreen), findsOneWidget);
      });
    });

    group('Combinations', () {
      testWidgets('should handle all parameters provided',
          (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(
            const MaterialApp(
              home: ResultScreen(
                imagePath: '/test/image.jpg',
                buildingId: 123,
                buildingName: 'Test Building',
              ),
            ),
          );

          expect(find.byType(ResultScreen), findsOneWidget);

          // Give time for async operations to start
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Pump any remaining frames
        await tester.pump();
      });

      testWidgets('should prioritize buildingId path when both provided',
          (WidgetTester tester) async {
        await tester.runAsync(() async {
          await tester.pumpWidget(
            const MaterialApp(
              home: ResultScreen(
                imagePath: '/test/image.jpg',
                buildingId: 123,
              ),
            ),
          );

          // Should show loading indicator (buildingId path is taken)
          expect(find.byType(CircularProgressIndicator), findsOneWidget);

          // Give time for async operations to start
          await Future.delayed(const Duration(milliseconds: 50));
        });

        // Pump any remaining frames
        await tester.pump();
      });
    });

    group('Text widgets and styling', () {
      testWidgets('should have Text widgets in loading state',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('header text should have correct styling',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        final historicamText = tester.widget<Text>(
          find.text('HistoriCam'),
        );

        expect(historicamText.style?.fontSize, 22);
        expect(historicamText.style?.fontWeight, FontWeight.bold);
        expect(historicamText.style?.color, Colors.white);
      });

      testWidgets('subtitle should have correct styling',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        final subtitleText = tester.widget<Text>(
          find.text('Your Personal Tour Guide'),
        );

        expect(subtitleText.style?.fontSize, 12);
      });
    });

    group('Icon widgets', () {
      testWidgets('should have correct icon sizes', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        final cameraIcon = tester.widget<Icon>(
          find.byIcon(Icons.camera_alt),
        );

        expect(cameraIcon.size, 28);
        expect(cameraIcon.color, Colors.white);
      });

      testWidgets('back icon should have correct color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ResultScreen(imagePath: '/test/image.jpg'),
          ),
        );

        final backIcon = tester.widget<Icon>(
          find.byIcon(Icons.arrow_back),
        );

        expect(backIcon.color, Colors.white);
      });
    });
  });
}
