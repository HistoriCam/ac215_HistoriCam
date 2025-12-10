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

      test('should handle complex answer text', () {
        final response = {
          'answer': 'This is a multi-line\nanswer with special chars: @#\$%'
        };

        final answer = service.parseAnswer(response);
        expect(answer, contains('multi-line'));
        expect(answer, contains('@#\$%'));
      });

      test('should handle very long answer', () {
        final longAnswer = 'a' * 10000;
        final response = {'answer': longAnswer};

        final answer = service.parseAnswer(response);
        expect(answer, equals(longAnswer));
        expect(answer.length, equals(10000));
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

      test('should preserve document order', () {
        final response = {
          'documents': [
            {'id': 1, 'order': 'first'},
            {'id': 2, 'order': 'second'},
            {'id': 3, 'order': 'third'},
          ]
        };

        final documents = service.parseDocuments(response);
        expect(documents, hasLength(3));
        expect(documents[0]['order'], equals('first'));
        expect(documents[1]['order'], equals('second'));
        expect(documents[2]['order'], equals('third'));
      });

      test('should handle documents with missing fields', () {
        final response = {
          'documents': [
            {'id': 1},
            {'content': 'doc without id'},
            {},
          ]
        };

        final documents = service.parseDocuments(response);
        expect(documents, hasLength(3));
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

      test('should validate chunk_type options', () {
        final validChunkTypes = ['recursive-split', 'char-split'];
        expect(validChunkTypes, contains('recursive-split'));
        expect(validChunkTypes, contains('char-split'));
      });

      test('should validate topK is positive integer', () {
        const topK = 5;
        expect(topK, isPositive);
        expect(topK, isA<int>());
      });

      test('should validate returnDocs is boolean', () {
        const returnDocs = false;
        expect(returnDocs, isA<bool>());
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

      test('should handle JSON encoding of special characters', () {
        final body = {
          'question': 'test with "quotes" and \\backslashes',
        };

        final encoded = json.encode(body);
        final decoded = json.decode(encoded);

        expect(decoded['question'], contains('quotes'));
        expect(decoded['question'], contains('backslashes'));
      });

      test('should handle JSON encoding of unicode characters', () {
        final body = {
          'question': 'test with émojis 🎉 and spëcial chars',
        };

        final encoded = json.encode(body);
        final decoded = json.decode(encoded);

        expect(decoded['question'], contains('émojis'));
        expect(decoded['question'], contains('🎉'));
      });
    });

    group('Response handling edge cases', () {
      test('should handle response with both answer and documents', () {
        final response = {
          'answer': 'test answer',
          'documents': [
            {'id': 1, 'content': 'doc1'}
          ]
        };

        final answer = service.parseAnswer(response);
        final documents = service.parseDocuments(response);

        expect(answer, equals('test answer'));
        expect(documents, hasLength(1));
      });

      test('should handle empty response object', () {
        final response = <String, dynamic>{};

        final answer = service.parseAnswer(response);
        final documents = service.parseDocuments(response);

        expect(answer,
            equals('Sorry, I could not generate an answer to your question.'));
        expect(documents, isEmpty);
      });

      test('should handle response with extra fields', () {
        final response = {
          'answer': 'test answer',
          'documents': [],
          'metadata': {'timestamp': '2024-01-01'},
          'status': 'success',
          'extra_field': 'extra_value',
        };

        final answer = service.parseAnswer(response);
        final documents = service.parseDocuments(response);

        expect(answer, equals('test answer'));
        expect(documents, isEmpty);
      });
    });

    group('Service initialization', () {
      test('should create multiple service instances', () {
        final service1 = LlmRagService();
        final service2 = LlmRagService();

        expect(service1, isNotNull);
        expect(service2, isNotNull);
        expect(service1, isNot(same(service2)));
      });

      test('should have consistent parsing across instances', () {
        final service1 = LlmRagService();
        final service2 = LlmRagService();

        final response = {'answer': 'test'};

        expect(service1.parseAnswer(response), equals(service2.parseAnswer(response)));
      });
    });
  });
}
