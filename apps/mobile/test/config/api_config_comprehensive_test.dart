import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/config/api_config.dart';

void main() {
  group('ApiConfig - Comprehensive Coverage', () {
    group('Configuration validation', () {
      test('isConfigured should return true for configured URL', () {
        expect(ApiConfig.isConfigured(), isTrue);
      });

      test('isLlmRagConfigured should return true for configured URL', () {
        expect(ApiConfig.isLlmRagConfigured(), isTrue);
      });

      test('visionApiUrl should be a valid URL', () {
        expect(ApiConfig.visionApiUrl, isNotEmpty);
        expect(ApiConfig.visionApiUrl.startsWith('http'), isTrue);
      });

      test('llmRagApiUrl should be a valid URL', () {
        expect(ApiConfig.llmRagApiUrl, isNotEmpty);
        expect(ApiConfig.llmRagApiUrl.startsWith('http'), isTrue);
      });

      test('visionApiUrl should not have trailing slash', () {
        expect(ApiConfig.visionApiUrl.endsWith('/'), isFalse);
      });

      test('llmRagApiUrl should not have trailing slash', () {
        expect(ApiConfig.llmRagApiUrl.endsWith('/'), isFalse);
      });
    });

    group('Endpoint generation', () {
      test('identifyEndpoint should have correct format', () {
        final endpoint = ApiConfig.identifyEndpoint;

        expect(endpoint, contains(ApiConfig.visionApiUrl));
        expect(endpoint, endsWith('/identify'));
        expect(endpoint.startsWith('http'), isTrue);
      });

      test('healthEndpoint should have correct format', () {
        final endpoint = ApiConfig.healthEndpoint;

        expect(endpoint, contains(ApiConfig.visionApiUrl));
        expect(endpoint, endsWith('/'));
        expect(endpoint.startsWith('http'), isTrue);
      });

      test('chatEndpoint should have correct format', () {
        final endpoint = ApiConfig.chatEndpoint;

        expect(endpoint, contains(ApiConfig.llmRagApiUrl));
        expect(endpoint, endsWith('/chat'));
        expect(endpoint.startsWith('http'), isTrue);
      });

      test('identifyEndpoint should combine base URL and path correctly', () {
        final endpoint = ApiConfig.identifyEndpoint;
        final expected = '${ApiConfig.visionApiUrl}/identify';

        expect(endpoint, equals(expected));
      });

      test('healthEndpoint should combine base URL correctly', () {
        final endpoint = ApiConfig.healthEndpoint;
        final expected = '${ApiConfig.visionApiUrl}/';

        expect(endpoint, equals(expected));
      });

      test('chatEndpoint should combine base URL and path correctly', () {
        final endpoint = ApiConfig.chatEndpoint;
        final expected = '${ApiConfig.llmRagApiUrl}/chat';

        expect(endpoint, equals(expected));
      });
    });

    group('URL structure validation', () {
      test('visionApiUrl should use HTTPS or localhost', () {
        final url = ApiConfig.visionApiUrl;
        expect(
          url.startsWith('https://') ||
          url.startsWith('http://localhost') ||
          url.startsWith('http://10.0.2.2'),
          isTrue,
        );
      });

      test('llmRagApiUrl should use HTTPS or localhost', () {
        final url = ApiConfig.llmRagApiUrl;
        expect(
          url.startsWith('https://') ||
          url.startsWith('http://localhost') ||
          url.startsWith('http://10.0.2.2'),
          isTrue,
        );
      });

      test('endpoints should be valid HTTP URLs', () {
        expect(Uri.tryParse(ApiConfig.identifyEndpoint), isNotNull);
        expect(Uri.tryParse(ApiConfig.healthEndpoint), isNotNull);
        expect(Uri.tryParse(ApiConfig.chatEndpoint), isNotNull);
      });

      test('endpoints should have valid URI scheme', () {
        final identifyUri = Uri.parse(ApiConfig.identifyEndpoint);
        final healthUri = Uri.parse(ApiConfig.healthEndpoint);
        final chatUri = Uri.parse(ApiConfig.chatEndpoint);

        expect(identifyUri.scheme, anyOf('http', 'https'));
        expect(healthUri.scheme, anyOf('http', 'https'));
        expect(chatUri.scheme, anyOf('http', 'https'));
      });
    });

    group('Constant values', () {
      test('visionApiUrl should be a const', () {
        expect(ApiConfig.visionApiUrl, isA<String>());
        expect(ApiConfig.visionApiUrl, isNotNull);
      });

      test('llmRagApiUrl should be a const', () {
        expect(ApiConfig.llmRagApiUrl, isA<String>());
        expect(ApiConfig.llmRagApiUrl, isNotNull);
      });

      test('should not modify base URLs', () {
        final vision1 = ApiConfig.visionApiUrl;
        final vision2 = ApiConfig.visionApiUrl;
        expect(vision1, equals(vision2));
        expect(identical(vision1, vision2), isTrue);
      });

      test('should return same endpoint instances', () {
        final identify1 = ApiConfig.identifyEndpoint;
        final identify2 = ApiConfig.identifyEndpoint;
        expect(identify1, equals(identify2));
      });
    });

    group('Endpoint paths', () {
      test('identifyEndpoint should have identify path', () {
        expect(ApiConfig.identifyEndpoint, contains('/identify'));
      });

      test('chatEndpoint should have chat path', () {
        expect(ApiConfig.chatEndpoint, contains('/chat'));
      });

      test('healthEndpoint should end with slash', () {
        expect(ApiConfig.healthEndpoint, endsWith('/'));
      });

      test('endpoints should not have double slashes in path', () {
        expect(ApiConfig.identifyEndpoint.contains('//'), isTrue); // Contains http://
        expect(ApiConfig.identifyEndpoint.substring(8).contains('//'), isFalse); // But not in the path
      });
    });

    group('Configuration scenarios', () {
      test('should handle production URL format', () {
        if (ApiConfig.visionApiUrl.contains('sslip.io') ||
            ApiConfig.visionApiUrl.contains('.run.app')) {
          expect(ApiConfig.visionApiUrl.startsWith('https://'), isTrue);
        }
      });

      test('should handle localhost URL format', () {
        if (ApiConfig.visionApiUrl.contains('localhost') ||
            ApiConfig.visionApiUrl.contains('10.0.2.2')) {
          expect(ApiConfig.visionApiUrl.startsWith('http://'), isTrue);
        }
      });

      test('isConfigured should validate localhost URLs', () {
        // Current configuration should be valid
        expect(ApiConfig.isConfigured(), isTrue);
      });

      test('isLlmRagConfigured should validate localhost URLs', () {
        // Current configuration should be valid
        expect(ApiConfig.isLlmRagConfigured(), isTrue);
      });
    });

    group('Endpoint accessibility', () {
      test('identifyEndpoint should be callable multiple times', () {
        final endpoint1 = ApiConfig.identifyEndpoint;
        final endpoint2 = ApiConfig.identifyEndpoint;
        final endpoint3 = ApiConfig.identifyEndpoint;

        expect(endpoint1, equals(endpoint2));
        expect(endpoint2, equals(endpoint3));
      });

      test('healthEndpoint should be callable multiple times', () {
        final endpoint1 = ApiConfig.healthEndpoint;
        final endpoint2 = ApiConfig.healthEndpoint;
        final endpoint3 = ApiConfig.healthEndpoint;

        expect(endpoint1, equals(endpoint2));
        expect(endpoint2, equals(endpoint3));
      });

      test('chatEndpoint should be callable multiple times', () {
        final endpoint1 = ApiConfig.chatEndpoint;
        final endpoint2 = ApiConfig.chatEndpoint;
        final endpoint3 = ApiConfig.chatEndpoint;

        expect(endpoint1, equals(endpoint2));
        expect(endpoint2, equals(endpoint3));
      });
    });

    group('URL components', () {
      test('identifyEndpoint should have correct components', () {
        final uri = Uri.parse(ApiConfig.identifyEndpoint);

        expect(uri.scheme, isNotEmpty);
        expect(uri.host, isNotEmpty);
        expect(uri.path, contains('identify'));
      });

      test('chatEndpoint should have correct components', () {
        final uri = Uri.parse(ApiConfig.chatEndpoint);

        expect(uri.scheme, isNotEmpty);
        expect(uri.host, isNotEmpty);
        expect(uri.path, contains('chat'));
      });

      test('healthEndpoint should have correct components', () {
        final uri = Uri.parse(ApiConfig.healthEndpoint);

        expect(uri.scheme, isNotEmpty);
        expect(uri.host, isNotEmpty);
      });
    });

    group('Static methods behavior', () {
      test('isConfigured should not throw exceptions', () {
        expect(() => ApiConfig.isConfigured(), returnsNormally);
      });

      test('isLlmRagConfigured should not throw exceptions', () {
        expect(() => ApiConfig.isLlmRagConfigured(), returnsNormally);
      });

      test('isConfigured should return boolean', () {
        expect(ApiConfig.isConfigured(), isA<bool>());
      });

      test('isLlmRagConfigured should return boolean', () {
        expect(ApiConfig.isLlmRagConfigured(), isA<bool>());
      });
    });

    group('Consistency checks', () {
      test('all endpoints should use same vision base URL', () {
        expect(ApiConfig.identifyEndpoint, startsWith(ApiConfig.visionApiUrl));
        expect(ApiConfig.healthEndpoint, startsWith(ApiConfig.visionApiUrl));
      });

      test('chat endpoint should use llm base URL', () {
        expect(ApiConfig.chatEndpoint, startsWith(ApiConfig.llmRagApiUrl));
      });

      test('base URLs should not contain path segments', () {
        final visionUri = Uri.parse(ApiConfig.visionApiUrl);
        final llmUri = Uri.parse(ApiConfig.llmRagApiUrl);

        // Base URLs should have minimal paths
        expect(visionUri.path, anyOf('', '/', startsWith('/vision')));
        expect(llmUri.path, anyOf('', '/', startsWith('/llm')));
      });
    });

    group('String operations', () {
      test('visionApiUrl should support string operations', () {
        expect(ApiConfig.visionApiUrl.length, greaterThan(0));
        expect(ApiConfig.visionApiUrl.toLowerCase(), isNotNull);
        expect(ApiConfig.visionApiUrl.toUpperCase(), isNotNull);
      });

      test('endpoint URLs should be valid strings', () {
        expect(ApiConfig.identifyEndpoint.length, greaterThan(0));
        expect(ApiConfig.healthEndpoint.length, greaterThan(0));
        expect(ApiConfig.chatEndpoint.length, greaterThan(0));
      });

      test('endpoint URLs should not be empty', () {
        expect(ApiConfig.identifyEndpoint, isNotEmpty);
        expect(ApiConfig.healthEndpoint, isNotEmpty);
        expect(ApiConfig.chatEndpoint, isNotEmpty);
      });
    });
  });
}
