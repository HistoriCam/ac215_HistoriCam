import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/config/api_config.dart';

void main() {
  group('ApiConfig', () {
    group('isConfigured', () {
      test('should return true for localhost URLs', () {
        // The current configuration uses localhost
        expect(ApiConfig.isConfigured(), true);
      });

      test('should validate that visionApiUrl is not empty', () {
        expect(ApiConfig.visionApiUrl, isNotEmpty);
      });

      test('should validate that visionApiUrl starts with http', () {
        expect(ApiConfig.visionApiUrl.startsWith('http'), true);
      });
    });

    group('identifyEndpoint', () {
      test('should return correct identify endpoint', () {
        expect(
          ApiConfig.identifyEndpoint,
          equals('${ApiConfig.visionApiUrl}/identify'),
        );
        expect(ApiConfig.identifyEndpoint, endsWith('/identify'));
      });

      test('should not have double slashes in endpoint', () {
        // URLs start with http:// or https://, so check for triple slashes or double slashes in path
        final endpoint = ApiConfig.identifyEndpoint;
        final pathPart = endpoint.replaceFirst(RegExp(r'https?://'), '');
        expect(pathPart, isNot(contains('//')));
      });
    });

    group('healthEndpoint', () {
      test('should return correct health endpoint', () {
        expect(
          ApiConfig.healthEndpoint,
          equals('${ApiConfig.visionApiUrl}/'),
        );
      });
    });

    group('URL validation', () {
      test('visionApiUrl should not have trailing slash', () {
        expect(ApiConfig.visionApiUrl.endsWith('/'), false);
      });

      test('visionApiUrl should be a valid URL format', () {
        const url = ApiConfig.visionApiUrl;
        expect(url, startsWith('http'));
        // Should not contain spaces or invalid characters
        expect(url, isNot(contains(' ')));
      });
    });

    group('LLM-RAG configuration', () {
      test('should have llmRagApiUrl configured', () {
        expect(ApiConfig.llmRagApiUrl, isNotEmpty);
      });

      test('llmRagApiUrl should start with http', () {
        expect(ApiConfig.llmRagApiUrl.startsWith('http'), true);
      });

      test('llmRagApiUrl should not have trailing slash', () {
        expect(ApiConfig.llmRagApiUrl.endsWith('/'), false);
      });

      test('isLlmRagConfigured should return true for localhost', () {
        expect(ApiConfig.isLlmRagConfigured(), true);
      });

      test('chatEndpoint should return correct endpoint', () {
        expect(
          ApiConfig.chatEndpoint,
          equals('${ApiConfig.llmRagApiUrl}/chat'),
        );
        expect(ApiConfig.chatEndpoint, endsWith('/chat'));
      });

      test('chatEndpoint should not have double slashes in path', () {
        final endpoint = ApiConfig.chatEndpoint;
        final pathPart = endpoint.replaceFirst(RegExp(r'https?://'), '');
        expect(pathPart, isNot(contains('//')));
      });
    });

    group('Endpoint getters', () {
      test('all endpoints should be non-empty', () {
        expect(ApiConfig.identifyEndpoint, isNotEmpty);
        expect(ApiConfig.healthEndpoint, isNotEmpty);
        expect(ApiConfig.chatEndpoint, isNotEmpty);
      });

      test('all endpoints should start with http', () {
        expect(ApiConfig.identifyEndpoint.startsWith('http'), true);
        expect(ApiConfig.healthEndpoint.startsWith('http'), true);
        expect(ApiConfig.chatEndpoint.startsWith('http'), true);
      });

      test('endpoints should have correct paths', () {
        expect(ApiConfig.identifyEndpoint, contains('/identify'));
        expect(ApiConfig.chatEndpoint, contains('/chat'));
      });
    });

    group('Configuration validation edge cases', () {
      test('visionApiUrl should be a const', () {
        const url1 = ApiConfig.visionApiUrl;
        const url2 = ApiConfig.visionApiUrl;
        expect(url1, equals(url2));
      });

      test('llmRagApiUrl should be a const', () {
        const url1 = ApiConfig.llmRagApiUrl;
        const url2 = ApiConfig.llmRagApiUrl;
        expect(url1, equals(url2));
      });

      test('endpoints should be consistent', () {
        final identify1 = ApiConfig.identifyEndpoint;
        final identify2 = ApiConfig.identifyEndpoint;
        expect(identify1, equals(identify2));
      });
    });
  });
}
