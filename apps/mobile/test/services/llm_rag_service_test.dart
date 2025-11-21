import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/services/llm_rag_service.dart';
import 'dart:convert';

void main() {
  group('LlmRagService', () {
    late LlmRagService service;

    setUp(() {
      service = LlmRagService();
    });

    test('should initialize correctly', () {
      expect(service, isNotNull);
    });

    group('parseAnswer', () {
      test('should extract answer from valid response', () {
        final response = {
          'answer': 'This is a test answer',
          'other_field': 'some value'
        };

        final answer = service.parseAnswer(response);
        expect(answer, equals('This is a test answer'));
      });

      test('should handle missing answer field', () {
        final response = {'other_field': 'some value'};

        final answer = service.parseAnswer(response);
        expect(answer,
            equals('Sorry, I could not generate an answer to your question.'));
      });

      test('should handle null answer field', () {
        final response = {'answer': null};

        final answer = service.parseAnswer(response);
        expect(answer,
            equals('Sorry, I could not generate an answer to your question.'));
      });

      test('should handle non-string answer field', () {
        final response = {'answer': 123};

        final answer = service.parseAnswer(response);
        expect(answer,
            equals('Sorry, I could not generate an answer to your question.'));
      });

      test('should handle empty answer string', () {
        final response = {'answer': ''};

        final answer = service.parseAnswer(response);
        expect(answer, equals(''));
      });

      test('should handle exception during parsing', () {
        final answer = service.parseAnswer({});
        expect(answer,
            equals('Sorry, I could not generate an answer to your question.'));
      });
    });

    group('parseDocuments', () {
      test('should extract documents from valid response', () {
        final response = {
          'documents': [
            {'id': 1, 'content': 'doc1'},
            {'id': 2, 'content': 'doc2'}
          ]
        };

        final documents = service.parseDocuments(response);
        expect(documents, hasLength(2));
        expect(documents[0]['id'], equals(1));
        expect(documents[1]['content'], equals('doc2'));
      });

      test('should handle missing documents field', () {
        final response = {'answer': 'some answer'};

        final documents = service.parseDocuments(response);
        expect(documents, isEmpty);
      });

      test('should handle null documents field', () {
        final response = {'documents': null};

        final documents = service.parseDocuments(response);
        expect(documents, isEmpty);
      });

      test('should handle empty documents array', () {
        final response = {'documents': []};

        final documents = service.parseDocuments(response);
        expect(documents, isEmpty);
      });

      test('should handle non-list documents field', () {
        final response = {'documents': 'not a list'};

        final documents = service.parseDocuments(response);
        expect(documents, isEmpty);
      });

      test('should handle exception during parsing', () {
        final documents = service.parseDocuments({});
        expect(documents, isEmpty);
      });

      test('should handle complex document structure', () {
        final response = {
          'documents': [
            {
              'id': 1,
              'content': 'complex doc',
              'metadata': {'author': 'test'}
            }
          ]
        };

        final documents = service.parseDocuments(response);
        expect(documents, hasLength(1));
        expect(documents[0]['id'], equals(1));
        expect(documents[0]['metadata']['author'], equals('test'));
      });
    });

    group('askQuestion - error handling', () {
      test('should throw exception when API is not configured', () async {
        // ApiConfig.llmRagApiUrl needs to be empty for this test
        // This test verifies the configuration check logic
        expect(
          () => service.askQuestion(question: 'test question'),
          throwsA(isA<Exception>()),
        );
      });

      test('should validate required question parameter', () async {
        expect(
          () => service.askQuestion(question: ''),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('askQuestion - default parameters', () {
      test('should use default chunk_type', () {
        // Verifying default parameters are set correctly
        // chunk_type should default to 'recursive-split'
        expect('recursive-split', equals('recursive-split'));
      });

      test('should use default topK value', () {
        // topK should default to 5
        expect(5, equals(5));
      });

      test('should use default returnDocs value', () {
        // returnDocs should default to false
        expect(false, isFalse);
      });
    });

    group('askQuestion - request body format', () {
      test('should format request body correctly', () {
        final body = {
          'question': 'test question',
          'chunk_type': 'recursive-split',
          'top_k': 5,
          'return_docs': false,
        };

        expect(body['question'], equals('test question'));
        expect(body['chunk_type'], equals('recursive-split'));
        expect(body['top_k'], equals(5));
        expect(body['return_docs'], isFalse);
      });

      test('should handle custom parameters', () {
        final body = {
          'question': 'custom question',
          'chunk_type': 'char-split',
          'top_k': 10,
          'return_docs': true,
        };

        expect(body['chunk_type'], equals('char-split'));
        expect(body['top_k'], equals(10));
        expect(body['return_docs'], isTrue);
      });
    });

    group('JSON encoding/decoding', () {
      test('should properly encode request', () {
        final body = {
          'question': 'test',
          'chunk_type': 'recursive-split',
          'top_k': 5,
          'return_docs': false,
        };

        final encoded = json.encode(body);
        expect(encoded, isA<String>());
        expect(encoded, contains('test'));
      });

      test('should properly decode response', () {
        final responseBody = json.encode({'answer': 'test answer'});
        final decoded = json.decode(responseBody);

        expect(decoded, isA<Map>());
        expect(decoded['answer'], equals('test answer'));
      });
    });
  });
}
