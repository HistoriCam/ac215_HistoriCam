import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/widgets/chatbot_widget.dart';

void main() {
  group('ChatMessage', () {
    test('should create message with all required fields', () {
      final message = ChatMessage(
        text: 'Hello, world!',
        isUser: true,
      );

      expect(message.text, equals('Hello, world!'));
      expect(message.isUser, isTrue);
      expect(message.isError, isFalse); // Default value
    });

    test('should create user message', () {
      final message = ChatMessage(
        text: 'User question',
        isUser: true,
      );

      expect(message.text, equals('User question'));
      expect(message.isUser, isTrue);
      expect(message.isError, isFalse);
    });

    test('should create bot message', () {
      final message = ChatMessage(
        text: 'Bot response',
        isUser: false,
      );

      expect(message.text, equals('Bot response'));
      expect(message.isUser, isFalse);
      expect(message.isError, isFalse);
    });

    test('should create error message', () {
      final message = ChatMessage(
        text: 'Error occurred',
        isUser: false,
        isError: true,
      );

      expect(message.text, equals('Error occurred'));
      expect(message.isUser, isFalse);
      expect(message.isError, isTrue);
    });

    test('should handle empty text', () {
      final message = ChatMessage(
        text: '',
        isUser: true,
      );

      expect(message.text, isEmpty);
      expect(message.isUser, isTrue);
    });

    test('should handle long text', () {
      final longText = 'a' * 1000;
      final message = ChatMessage(
        text: longText,
        isUser: false,
      );

      expect(message.text, equals(longText));
      expect(message.text.length, equals(1000));
    });

    test('should handle special characters in text', () {
      final message = ChatMessage(
        text: 'Hello! @#\$%^&*() 🎉',
        isUser: true,
      );

      expect(message.text, equals('Hello! @#\$%^&*() 🎉'));
    });

    test('should handle multiline text', () {
      final message = ChatMessage(
        text: 'Line 1\nLine 2\nLine 3',
        isUser: false,
      );

      expect(message.text, contains('\n'));
      expect(message.text.split('\n').length, equals(3));
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

    test('should default isError to false when not specified', () {
      final message = ChatMessage(
        text: 'Normal message',
        isUser: false,
      );

      expect(message.isError, isFalse);
    });
  });
}
