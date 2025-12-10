import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/widgets/chatbot_widget.dart';

void main() {
  group('ChatbotWidget - Comprehensive Coverage', () {
    group('ChatMessage class', () {
      test('should create user message', () {
        final message = ChatMessage(
          text: 'Hello',
          isUser: true,
        );

        expect(message.text, 'Hello');
        expect(message.isUser, isTrue);
        expect(message.isError, isFalse);
      });

      test('should create bot message', () {
        final message = ChatMessage(
          text: 'Hi there',
          isUser: false,
        );

        expect(message.text, 'Hi there');
        expect(message.isUser, isFalse);
        expect(message.isError, isFalse);
      });

      test('should create error message', () {
        final message = ChatMessage(
          text: 'Error occurred',
          isUser: false,
          isError: true,
        );

        expect(message.text, 'Error occurred');
        expect(message.isUser, isFalse);
        expect(message.isError, isTrue);
      });

      test('should default isError to false', () {
        final message = ChatMessage(
          text: 'Test',
          isUser: true,
        );

        expect(message.isError, isFalse);
      });

      test('should handle empty text', () {
        final message = ChatMessage(
          text: '',
          isUser: true,
        );

        expect(message.text, '');
      });

      test('should handle very long text', () {
        final longText = 'A' * 10000;
        final message = ChatMessage(
          text: longText,
          isUser: true,
        );

        expect(message.text, longText);
        expect(message.text.length, 10000);
      });

      test('should handle unicode text', () {
        final message = ChatMessage(
          text: '你好世界 🌍',
          isUser: true,
        );

        expect(message.text, '你好世界 🌍');
      });

      test('should handle special characters', () {
        final message = ChatMessage(
          text: 'Test @#\$%^&*()',
          isUser: false,
        );

        expect(message.text, 'Test @#\$%^&*()');
      });

      test('should handle newlines in text', () {
        final message = ChatMessage(
          text: 'Line 1\nLine 2\nLine 3',
          isUser: true,
        );

        expect(message.text, contains('\n'));
        expect(message.text, 'Line 1\nLine 2\nLine 3');
      });

      test('should allow user error messages', () {
        final message = ChatMessage(
          text: 'User error',
          isUser: true,
          isError: true,
        );

        expect(message.isUser, isTrue);
        expect(message.isError, isTrue);
      });
    });

    group('Widget initialization', () {
      testWidgets('should initialize without context',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        expect(find.byType(ChatbotWidget), findsOneWidget);
      });

      testWidgets('should initialize with empty context',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(initialContext: ''),
            ),
          ),
        );

        expect(find.byType(ChatbotWidget), findsOneWidget);
      });

      testWidgets('should initialize with very long context',
          (WidgetTester tester) async {
        final longContext = 'A' * 10000;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(initialContext: longContext),
            ),
          ),
        );

        expect(find.byType(ChatbotWidget), findsOneWidget);
      });

      testWidgets('should initialize with unicode context',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(initialContext: '艾菲爾鐵塔 🗼'),
            ),
          ),
        );

        expect(find.byType(ChatbotWidget), findsOneWidget);
      });
    });

    group('Header styling', () {
      testWidgets('should have correct header color',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final headerContainer = tester.widget<Container>(
          find.ancestor(
            of: find.text('Ask Anything'),
            matching: find.byType(Container),
          ).first,
        );

        expect(headerContainer.decoration, isA<BoxDecoration>());
        final decoration = headerContainer.decoration as BoxDecoration;
        expect(decoration.color, const Color(0xFF2B2B2B));
      });

      testWidgets('should have chat bubble icon',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);

        final icon = tester.widget<Icon>(
          find.byIcon(Icons.chat_bubble_outline),
        );
        expect(icon.color, Colors.white);
        expect(icon.size, 20);
      });

      testWidgets('should have circular icon container',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final iconContainer = tester.widget<Container>(
          find.ancestor(
            of: find.byIcon(Icons.chat_bubble_outline),
            matching: find.byType(Container),
          ).first,
        );

        expect(iconContainer.decoration, isA<BoxDecoration>());
        final decoration = iconContainer.decoration as BoxDecoration;
        expect(decoration.shape, BoxShape.circle);
        expect(decoration.color, const Color(0xFFE63946));
      });

      testWidgets('should have Spacer in header Row',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final spacer = find.descendant(
          of: find.ancestor(
            of: find.text('Ask Anything'),
            matching: find.byType(Row),
          ),
          matching: find.byType(Spacer),
        );

        expect(spacer, findsOneWidget);
      });
    });

    group('Social icons', () {
      testWidgets('should have all social icons', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        expect(find.byIcon(Icons.facebook), findsOneWidget);
        expect(find.byIcon(Icons.link), findsOneWidget);
        expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
        expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      });

      testWidgets('social icons should have circular containers',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final socialIconContainers = tester.widgetList<Container>(
          find.ancestor(
            of: find.byIcon(Icons.facebook),
            matching: find.byType(Container),
          ),
        );

        expect(socialIconContainers, isNotEmpty);

        for (final container in socialIconContainers) {
          if (container.decoration is BoxDecoration) {
            final decoration = container.decoration as BoxDecoration;
            if (decoration.shape == BoxShape.circle) {
              expect(decoration.color, const Color(0xFF2B2B2B));
            }
          }
        }
      });

      testWidgets('should have Row for social icons',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final socialRow = find.ancestor(
          of: find.byIcon(Icons.facebook),
          matching: find.byType(Row),
        );

        expect(socialRow, findsWidgets);
      });
    });

    group('Input field', () {
      testWidgets('should have TextField', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('TextField should have correct hint',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.decoration?.hintText,
            'Ask anything (eg. Where to next?)');
      });

      testWidgets('TextField should have filled style',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.decoration?.filled, isTrue);
        expect(textField.decoration?.fillColor, const Color(0xFFF5F5F5));
      });

      testWidgets('TextField should have rounded border',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final textField = tester.widget<TextField>(find.byType(TextField));
        expect(textField.decoration?.border, isA<OutlineInputBorder>());
      });

      testWidgets('should have Expanded wrapping TextField',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final expanded = find.ancestor(
          of: find.byType(TextField),
          matching: find.byType(Expanded),
        );

        expect(expanded, findsOneWidget);
      });
    });

    group('Send button', () {
      testWidgets('should have send IconButton', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        expect(find.byIcon(Icons.send), findsOneWidget);

        final iconButton = find.ancestor(
          of: find.byIcon(Icons.send),
          matching: find.byType(IconButton),
        );
        expect(iconButton, findsOneWidget);
      });

      testWidgets('send button should have circular container',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final sendContainer = tester.widget<Container>(
          find.ancestor(
            of: find.byIcon(Icons.send),
            matching: find.byType(Container),
          ).first,
        );

        expect(sendContainer.decoration, isA<BoxDecoration>());
        final decoration = sendContainer.decoration as BoxDecoration;
        expect(decoration.shape, BoxShape.circle);
        expect(decoration.color, const Color(0xFFE63946));
      });

      testWidgets('send icon should be white', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final icon = tester.widget<Icon>(find.byIcon(Icons.send));
        expect(icon.color, Colors.white);
      });
    });

    group('Messages ListView', () {
      testWidgets('should have ListView.builder', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        expect(find.byType(ListView), findsOneWidget);
      });

      testWidgets('ListView should have correct constraints',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final constrainedBox = tester.widget<Container>(
          find.ancestor(
            of: find.byType(ListView),
            matching: find.byType(Container),
          ).first,
        );

        expect(constrainedBox.constraints, isNotNull);
        expect(constrainedBox.constraints?.maxHeight, 300);
      });
    });

    group('Layout structure', () {
      testWidgets('should have main Column layout',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        expect(find.byType(Column), findsWidgets);
      });

      testWidgets('should have Row for input and send button',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final inputRow = find.ancestor(
          of: find.byType(TextField),
          matching: find.byType(Row),
        );

        expect(inputRow, findsWidgets);
      });

      testWidgets('should have Container with white background',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final mainContainer = tester.widget<Container>(
          find.byType(Container).first,
        );

        expect(mainContainer.decoration, isA<BoxDecoration>());
        final decoration = mainContainer.decoration as BoxDecoration;
        expect(decoration.color, Colors.white);
      });

      testWidgets('should have rounded corners on main container',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final mainContainer = tester.widget<Container>(
          find.byType(Container).first,
        );

        final decoration = mainContainer.decoration as BoxDecoration;
        expect(decoration.borderRadius, isNotNull);
      });

      testWidgets('should have shadow on main container',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final mainContainer = tester.widget<Container>(
          find.byType(Container).first,
        );

        final decoration = mainContainer.decoration as BoxDecoration;
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow, isNotEmpty);
      });
    });

    group('Empty message validation', () {
      testWidgets('should not send empty message', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        // Try to send without entering text
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        // Should not show any user messages
        expect(find.byIcon(Icons.person), findsNothing);
      });

      testWidgets('should not send whitespace-only message',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        // Enter whitespace
        await tester.enterText(find.byType(TextField), '   ');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pump();

        // Should not show any user messages
        expect(find.byIcon(Icons.person), findsNothing);
      });
    });

    group('Multiple SizedBox for spacing', () {
      testWidgets('should have SizedBox widgets for spacing',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        expect(find.byType(SizedBox), findsWidgets);
      });

      testWidgets('should have SizedBox in header Row',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final sizedBoxInHeader = find.descendant(
          of: find.ancestor(
            of: find.text('Ask Anything'),
            matching: find.byType(Row),
          ),
          matching: find.byType(SizedBox),
        );

        expect(sizedBoxInHeader, findsWidgets);
      });

      testWidgets('should have SizedBox between input and send button',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final sizedBoxInInputRow = find.descendant(
          of: find.ancestor(
            of: find.byType(TextField),
            matching: find.byType(Row),
          ),
          matching: find.byType(SizedBox),
        );

        expect(sizedBoxInInputRow, findsWidgets);
      });
    });

    group('Text styling', () {
      testWidgets('header title should have correct style',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final titleText = tester.widget<Text>(find.text('Ask Anything'));
        expect(titleText.style?.color, Colors.white);
        expect(titleText.style?.fontSize, 18);
        expect(titleText.style?.fontWeight, FontWeight.bold);
      });

      testWidgets('header subtitle should have correct style',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final subtitleText = tester.widget<Text>(
          find.text('(eg. Where to next?)'),
        );
        expect(subtitleText.style?.color, Colors.white70);
        expect(subtitleText.style?.fontSize, 12);
        expect(subtitleText.style?.fontStyle, FontStyle.italic);
      });
    });

    group('Input Row layout', () {
      testWidgets('should have containers around input row',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ChatbotWidget(),
            ),
          ),
        );

        final inputContainers = find.ancestor(
          of: find.byType(TextField),
          matching: find.byType(Container),
        );

        // Should find multiple containers (main container + input container)
        expect(inputContainers, findsWidgets);
      });
    });
  });
}
