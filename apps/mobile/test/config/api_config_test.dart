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
        expect(ApiConfig.identifyEndpoint, isNot(contains('//')));
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
  });
}
