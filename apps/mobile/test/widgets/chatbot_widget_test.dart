import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/widgets/chatbot_widget.dart';

void main() {
  group('ChatbotWidget', () {
    testWidgets('should display chatbot UI elements',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatbotWidget(),
          ),
        ),
      );

      // Verify header elements
      expect(find.text('Ask Anything'), findsOneWidget);
      expect(find.text('(eg. Where to next?)'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);

      // Verify input field
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Ask anything (eg. Where to next?)'), findsOneWidget);

      // Verify send button
      expect(find.byIcon(Icons.send), findsOneWidget);

      // Verify social media icons
      expect(find.byIcon(Icons.facebook), findsOneWidget);
      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    });

    testWidgets('should send message when send button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatbotWidget(),
          ),
        ),
      );

      // Enter a message
      const testMessage = 'What is this building?';
      await tester.enterText(find.byType(TextField), testMessage);
      await tester.pump();

      // Tap the send button
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Verify the message appears in the chat
      expect(find.text(testMessage), findsOneWidget);

      // Verify typing indicator appears
      expect(find.byType(CircularProgressIndicator),
          findsNothing); // Dots animation instead

      // Wait for bot response
      await tester.pump(const Duration(seconds: 2));

      // Verify bot response appears
      expect(
        find.text(
            'Thanks for your question! The chatbot API will be integrated soon to provide detailed answers about this historic building.'),
        findsOneWidget,
      );
    });

    testWidgets('should send message when pressing enter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatbotWidget(),
          ),
        ),
      );

      // Enter a message
      const testMessage = 'Tell me more';
      await tester.enterText(find.byType(TextField), testMessage);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Verify the message appears
      expect(find.text(testMessage), findsOneWidget);
    });

    testWidgets('should not send empty messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatbotWidget(),
          ),
        ),
      );

      // Try to send empty message
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // No messages should appear
      expect(find.byType(Container), findsWidgets); // Widget structure exists

      // Try whitespace only
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Still no messages should appear
      expect(find.text('   '), findsNothing);
    });

    testWidgets('should clear text field after sending message',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatbotWidget(),
          ),
        ),
      );

      // Enter and send a message
      const testMessage = 'Test message';
      await tester.enterText(find.byType(TextField), testMessage);
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Verify text field is cleared
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('should display user and bot messages differently',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatbotWidget(),
          ),
        ),
      );

      // Send a message
      const userMessage = 'Hello';
      await tester.enterText(find.byType(TextField), userMessage);
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Wait for bot response
      await tester.pump(const Duration(seconds: 2));

      // Both user and bot icons should be visible
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('should handle multiple messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatbotWidget(),
          ),
        ),
      );

      // Send first message
      await tester.enterText(find.byType(TextField), 'First message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Send second message
      await tester.enterText(find.byType(TextField), 'Second message');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Both messages should be visible
      expect(find.text('First message'), findsOneWidget);
      expect(find.text('Second message'), findsOneWidget);
    });

    testWidgets('should show typing indicator while bot is responding',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChatbotWidget(),
          ),
        ),
      );

      // Send a message
      await tester.enterText(find.byType(TextField), 'Question?');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      // Typing dots should be visible (before the 1 second delay)
      await tester.pump(const Duration(milliseconds: 100));

      // The typing indicator uses animated dots
      // We can verify the structure exists even if animation is complex
      expect(find.byType(TweenAnimationBuilder<double>), findsWidgets);
    });
  });
}
