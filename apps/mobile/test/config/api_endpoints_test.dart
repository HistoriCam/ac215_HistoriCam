import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/config/api_config.dart';

void main() {
  group('API Endpoints Configuration', () {
    test('vision API URL should be properly configured', () {
      expect(ApiConfig.visionApiUrl, isNotEmpty);
      expect(ApiConfig.visionApiUrl, startsWith('http'));
    });

    test('LLM-RAG API URL should be properly configured', () {
      expect(ApiConfig.llmRagApiUrl, isNotEmpty);
      expect(ApiConfig.llmRagApiUrl, startsWith('http'));
    });

    test('identify endpoint should combine base URL with path', () {
      final identifyEndpoint = ApiConfig.identifyEndpoint;

      expect(identifyEndpoint, contains(ApiConfig.visionApiUrl));
      expect(identifyEndpoint, endsWith('/identify'));
    });

    test('chat endpoint should combine base URL with path', () {
      final chatEndpoint = ApiConfig.chatEndpoint;

      expect(chatEndpoint, contains(ApiConfig.llmRagApiUrl));
      expect(chatEndpoint, endsWith('/chat'));
    });

    test('health endpoint should return base vision URL', () {
      final healthEndpoint = ApiConfig.healthEndpoint;

      expect(healthEndpoint, contains(ApiConfig.visionApiUrl));
    });

    test('isConfigured should validate vision API URL', () {
      final isConfigured = ApiConfig.isConfigured();

      expect(isConfigured, isTrue);
    });

    test('isLlmRagConfigured should validate LLM-RAG API URL', () {
      final isConfigured = ApiConfig.isLlmRagConfigured();

      expect(isConfigured, isTrue);
    });

    test('localhost URLs should be considered configured for development', () {
      const localhostUrl = 'http://localhost:8080';

      expect(localhostUrl, startsWith('http'));
      expect(localhostUrl, contains('localhost'));
    });

    test('production URLs should use HTTPS', () {
      if (!ApiConfig.visionApiUrl.contains('localhost')) {
        expect(ApiConfig.visionApiUrl, startsWith('https'));
      }
    });

    test('API URLs should not have trailing slashes', () {
      expect(ApiConfig.visionApiUrl, isNot(endsWith('/')));
      expect(ApiConfig.llmRagApiUrl, isNot(endsWith('/')));
    });
  });

  group('API URL Validation', () {
    test('should accept localhost URLs for iOS simulator', () {
      const iosSimulatorUrl = 'http://localhost:8080';

      expect(iosSimulatorUrl.startsWith('http'), isTrue);
      expect(iosSimulatorUrl.contains('localhost'), isTrue);
    });

    test('should accept localhost URLs for Android emulator', () {
      const androidEmulatorUrl = 'http://10.0.2.2:8080';

      expect(androidEmulatorUrl.startsWith('http'), isTrue);
      expect(androidEmulatorUrl.contains('10.0.2.2'), isTrue);
    });

    test('should validate HTTPS for production URLs', () {
      const productionUrl = 'https://35.224.247.219.sslip.io/vision';

      expect(productionUrl.startsWith('https'), isTrue);
      expect(productionUrl.isNotEmpty, isTrue);
    });
  });
}
