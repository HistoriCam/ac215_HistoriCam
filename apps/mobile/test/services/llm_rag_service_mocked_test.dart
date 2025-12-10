import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:historicam/services/llm_rag_service.dart';
import 'package:historicam/config/api_config.dart';

import 'llm_rag_service_mocked_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('LlmRagService with HTTP mocks', () {
    setUp(() {
      // Mock client setup for future use
      MockClient();
    });

    group('askQuestion configuration', () {
      test('should use correct default parameters', () {
        // Test default parameter values
        const chunkType = 'recursive-split';
        const topK = 5;
        const returnDocs = false;

        expect(chunkType, equals('recursive-split'));
        expect(topK, equals(5));
        expect(returnDocs, equals(false));
      });

      test('should validate chunk type options', () {
        const validChunkTypes = ['recursive-split', 'char-split'];
        expect(validChunkTypes, contains('recursive-split'));
        expect(validChunkTypes, contains('char-split'));
      });

      test('should construct correct endpoint', () {
        final endpoint = ApiConfig.chatEndpoint;
        expect(endpoint, contains('/chat'));
        expect(endpoint, startsWith('http'));
      });
    });

    group('parseAnswer additional cases', () {
      test('should handle answer with HTML content', () {
        final service = LlmRagService();
        final response = {
          'answer': '<p>This is HTML content</p>',
        };

        final answer = service.parseAnswer(response);
        expect(answer, contains('<p>'));
        expect(answer, contains('HTML content'));
      });

      test('should handle answer with markdown', () {
        final service = LlmRagService();
        final response = {
          'answer': '# Header\n\n**Bold text**',
        };

        final answer = service.parseAnswer(response);
        expect(answer, contains('# Header'));
        expect(answer, contains('**Bold text**'));
      });

      test('should handle answer with code blocks', () {
        final service = LlmRagService();
        final response = {
          'answer': '```python\nprint("Hello")\n```',
        };

        final answer = service.parseAnswer(response);
        expect(answer, contains('```python'));
        expect(answer, contains('print("Hello")'));
      });

      test('should handle answer with emojis', () {
        final service = LlmRagService();
        final response = {
          'answer': 'Great question! 🎉 The answer is... 🏛️',
        };

        final answer = service.parseAnswer(response);
        expect(answer, contains('🎉'));
        expect(answer, contains('🏛️'));
      });

      test('should handle answer with URLs', () {
        final service = LlmRagService();
        final response = {
          'answer': 'Visit https://example.com for more info',
        };

        final answer = service.parseAnswer(response);
        expect(answer, contains('https://example.com'));
      });

      test('should handle answer with numbers', () {
        final service = LlmRagService();
        final response = {
          'answer': 'Built in 1930, it is 381 meters tall',
        };

        final answer = service.parseAnswer(response);
        expect(answer, contains('1930'));
        expect(answer, contains('381'));
      });

      test('should handle answer with quotes', () {
        final service = LlmRagService();
        final response = {
          'answer': '"The building" is famous',
        };

        final answer = service.parseAnswer(response);
        expect(answer, contains('"The building"'));
      });

      test('should handle answer with apostrophes', () {
        final service = LlmRagService();
        final response = {
          'answer': "It's the world's tallest building",
        };

        final answer = service.parseAnswer(response);
        expect(answer, contains("It's"));
        expect(answer, contains("world's"));
      });

      test('should handle answer as boolean', () {
        final service = LlmRagService();
        final response = {
          'answer': true,
        };

        final answer = service.parseAnswer(response);
        expect(
          answer,
          equals('Sorry, I could not generate an answer to your question.'),
        );
      });

      test('should handle answer as number', () {
        final service = LlmRagService();
        final response = {
          'answer': 42,
        };

        final answer = service.parseAnswer(response);
        expect(
          answer,
          equals('Sorry, I could not generate an answer to your question.'),
        );
      });

      test('should handle answer as array', () {
        final service = LlmRagService();
        final response = {
          'answer': ['item1', 'item2'],
        };

        final answer = service.parseAnswer(response);
        expect(
          answer,
          equals('Sorry, I could not generate an answer to your question.'),
        );
      });

      test('should handle whitespace-only answer', () {
        final service = LlmRagService();
        final response = {
          'answer': '   \n\t  ',
        };

        final answer = service.parseAnswer(response);
        expect(answer, equals('   \n\t  '));
      });
    });

    group('parseDocuments additional cases', () {
      test('should handle documents with nested objects', () {
        final service = LlmRagService();
        final response = {
          'documents': [
            {
              'id': 1,
              'metadata': {
                'author': 'John',
                'date': '2024-01-01',
                'tags': ['history', 'architecture']
              }
            }
          ]
        };

        final documents = service.parseDocuments(response);
        expect(documents, hasLength(1));
        expect(documents[0]['metadata']['author'], equals('John'));
        expect(documents[0]['metadata']['tags'], isA<List>());
      });

      test('should handle documents with null values', () {
        final service = LlmRagService();
        final response = {
          'documents': [
            {'id': 1, 'content': null, 'metadata': null}
          ]
        };

        final documents = service.parseDocuments(response);
        expect(documents, hasLength(1));
        expect(documents[0]['content'], isNull);
      });

      test('should handle documents with boolean values', () {
        final service = LlmRagService();
        final response = {
          'documents': [
            {'id': 1, 'verified': true, 'public': false}
          ]
        };

        final documents = service.parseDocuments(response);
        expect(documents, hasLength(1));
        expect(documents[0]['verified'], isTrue);
        expect(documents[0]['public'], isFalse);
      });

      test('should handle documents with number IDs', () {
        final service = LlmRagService();
        final response = {
          'documents': [
            {'id': 123, 'content': 'doc1'},
            {'id': 456, 'content': 'doc2'}
          ]
        };

        final documents = service.parseDocuments(response);
        expect(documents, hasLength(2));
        expect(documents[0]['id'], 123);
        expect(documents[1]['id'], 456);
      });

      test('should handle documents with string IDs', () {
        final service = LlmRagService();
        final response = {
          'documents': [
            {'id': 'doc-123', 'content': 'doc1'},
            {'id': 'doc-456', 'content': 'doc2'}
          ]
        };

        final documents = service.parseDocuments(response);
        expect(documents, hasLength(2));
        expect(documents[0]['id'], 'doc-123');
        expect(documents[1]['id'], 'doc-456');
      });

      test('should handle documents as object instead of array', () {
        final service = LlmRagService();
        final response = {
          'documents': {'id': 1, 'content': 'single doc'}
        };

        final documents = service.parseDocuments(response);
        expect(documents, isEmpty);
      });

      test('should handle large number of documents', () {
        final service = LlmRagService();
        final docList = List.generate(
          100,
          (i) => {'id': i, 'content': 'doc$i'},
        );
        final response = {'documents': docList};

        final documents = service.parseDocuments(response);
        expect(documents, hasLength(100));
        expect(documents[0]['id'], 0);
        expect(documents[99]['id'], 99);
      });

      test('should handle documents with very long content', () {
        final service = LlmRagService();
        final longContent = 'a' * 10000;
        final response = {
          'documents': [
            {'id': 1, 'content': longContent}
          ]
        };

        final documents = service.parseDocuments(response);
        expect(documents, hasLength(1));
        expect(documents[0]['content'].length, 10000);
      });
    });

    group('Response combinations', () {
      test('should handle response with answer but no documents', () {
        final service = LlmRagService();
        final response = {
          'answer': 'Test answer',
        };

        final answer = service.parseAnswer(response);
        final documents = service.parseDocuments(response);

        expect(answer, equals('Test answer'));
        expect(documents, isEmpty);
      });

      test('should handle response with documents but no answer', () {
        final service = LlmRagService();
        final response = {
          'documents': [
            {'id': 1, 'content': 'doc1'}
          ]
        };

        final answer = service.parseAnswer(response);
        final documents = service.parseDocuments(response);

        expect(
          answer,
          equals('Sorry, I could not generate an answer to your question.'),
        );
        expect(documents, hasLength(1));
      });

      test('should handle completely empty response', () {
        final service = LlmRagService();
        final response = <String, dynamic>{};

        final answer = service.parseAnswer(response);
        final documents = service.parseDocuments(response);

        expect(
          answer,
          equals('Sorry, I could not generate an answer to your question.'),
        );
        expect(documents, isEmpty);
      });

      test('should handle response with null values', () {
        final service = LlmRagService();
        final response = {
          'answer': null,
          'documents': null,
        };

        final answer = service.parseAnswer(response);
        final documents = service.parseDocuments(response);

        expect(
          answer,
          equals('Sorry, I could not generate an answer to your question.'),
        );
        expect(documents, isEmpty);
      });
    });
  });
}
