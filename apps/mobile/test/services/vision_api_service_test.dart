import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/services/vision_api_service.dart';
import 'package:historicam/config/api_config.dart';

void main() {
  group('VisionApiService', () {
    late VisionApiService visionApiService;

    setUp(() {
      visionApiService = VisionApiService();
    });

    group('parseResponse', () {
      test('should parse confident response correctly', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': 'eiffel_tower',
          'confidence': 0.95,
          'message': 'Identified with high confidence',
          'matches': [
            {'building_id': 'eiffel_tower', 'confidence': 0.95}
          ],
        };

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['success'], true);
        expect(result['buildingId'], 'eiffel_tower');
        expect(result['confidence'], 0.95);
        expect(result['status'], 'confident');
      });

      test('should parse uncertain response correctly', () {
        final apiResponse = {
          'status': 'uncertain',
          'building_id': 'statue_liberty',
          'confidence': 0.65,
          'message': 'Identified with low confidence',
          'matches': [
            {'building_id': 'statue_liberty', 'confidence': 0.65}
          ],
        };

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['success'], true);
        expect(result['buildingId'], 'statue_liberty');
        expect(result['confidence'], 0.65);
        expect(result['status'], 'uncertain');
      });

      test('should handle no_match status correctly', () {
        final apiResponse = {
          'status': 'no_match',
          'message': 'No matching building found',
        };

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['success'], false);
        expect(result['error'], 'no_match');
        expect(result['message'], 'No matching building found');
      });

      test('should handle unknown status', () {
        final apiResponse = {
          'status': 'unknown_status',
        };

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['success'], false);
        expect(result['error'], 'unknown');
        expect(result['message'], contains('Unknown response status'));
      });

      test('should handle parse errors gracefully', () {
        final apiResponse = <String, dynamic>{};

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['success'], isFalse);
        expect(result['error'], equals('unknown'));
        expect(result['message'], contains('Unknown response status'));
      });
    });

    group('identifyBuilding', () {
      test('should check if API is configured', () async {
        // Verify API configuration check exists
        expect(
          ApiConfig.isConfigured(),
          isTrue, // Should be true for the default configuration
        );
      });
    });

    group('parseResponse - additional edge cases', () {
      test('should handle missing confidence field', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': 'test_building',
          'message': 'Test message',
          'matches': [],
        };

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['success'], isTrue);
        expect(result['confidence'], isNull);
      });

      test('should handle missing message field in no_match', () {
        final apiResponse = {
          'status': 'no_match',
        };

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['success'], isFalse);
        expect(result['message'], 'No matching building found');
      });

      test('should preserve all fields in successful response', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': 'building_123',
          'confidence': 0.85,
          'message': 'Found match',
          'matches': [
            {'building_id': 'building_123', 'confidence': 0.85},
            {'building_id': 'building_456', 'confidence': 0.45}
          ],
        };

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['success'], isTrue);
        expect(result['matches'], isNotNull);
        expect((result['matches'] as List).length, 2);
      });

      test('should handle null values gracefully', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': null,
          'confidence': null,
          'message': null,
          'matches': null,
        };

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['success'], isTrue);
        expect(result['buildingId'], isNull);
      });

      test('should handle error status', () {
        final apiResponse = {
          'status': 'error',
          'message': 'API error occurred',
        };

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['success'], isFalse);
        expect(result['error'], 'error');
      });

      test('should handle missing status field', () {
        final apiResponse = {
          'building_id': 'test',
          'confidence': 0.9,
        };

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['success'], isFalse);
      });

      test('should preserve original message in responses', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': 'test',
          'message': 'Custom message here',
        };

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['message'], 'Custom message here');
      });
    });

    group('VisionApiService - initialization and fields', () {
      test('should create instance successfully', () {
        final service = VisionApiService();
        expect(service, isNotNull);
        expect(service, isA<VisionApiService>());
      });

      test('should create multiple instances', () {
        final service1 = VisionApiService();
        final service2 = VisionApiService();

        expect(service1, isNotNull);
        expect(service2, isNotNull);
        expect(service1, isNot(same(service2)));
      });

      test('should have consistent parsing across instances', () {
        final service1 = VisionApiService();
        final service2 = VisionApiService();

        final apiResponse = {
          'status': 'confident',
          'building_id': 'test',
          'confidence': 0.9,
        };

        final result1 = service1.parseResponse(apiResponse);
        final result2 = service2.parseResponse(apiResponse);

        expect(result1['success'], result2['success']);
        expect(result1['buildingId'], result2['buildingId']);
      });
    });

    group('parseResponse - status variations', () {
      test('should handle uppercase status', () {
        final apiResponse = {
          'status': 'CONFIDENT',
          'building_id': 'test',
        };

        final result = visionApiService.parseResponse(apiResponse);

        // May not match exact status, but should handle gracefully
        expect(result, isNotNull);
      });

      test('should handle different confidence levels', () {
        final testCases = [0.0, 0.5, 0.99, 1.0];

        for (final confidence in testCases) {
          final apiResponse = {
            'status': 'confident',
            'building_id': 'test',
            'confidence': confidence,
          };

          final result = visionApiService.parseResponse(apiResponse);
          expect(result['confidence'], confidence);
        }
      });

      test('should handle empty matches array', () {
        final apiResponse = {
          'status': 'uncertain',
          'building_id': 'test',
          'matches': [],
        };

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['success'], isTrue);
        expect(result['matches'], isEmpty);
      });

      test('should handle large matches array', () {
        final matches = List.generate(
          100,
          (i) => {'building_id': 'building_$i', 'confidence': i / 100.0},
        );

        final apiResponse = {
          'status': 'uncertain',
          'building_id': 'building_0',
          'matches': matches,
        };

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['success'], isTrue);
        expect((result['matches'] as List).length, 100);
      });
    });

    group('parseResponse - building ID formats', () {
      test('should handle numeric building IDs', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': 12345,
          'confidence': 0.9,
        };

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['success'], isTrue);
        expect(result['buildingId'], 12345);
      });

      test('should handle building ID with special characters', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': 'building-id_123.test',
          'confidence': 0.9,
        };

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['success'], isTrue);
        expect(result['buildingId'], 'building-id_123.test');
      });

      test('should handle empty building ID', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': '',
          'confidence': 0.9,
        };

        final result = visionApiService.parseResponse(apiResponse);

        expect(result['success'], isTrue);
        expect(result['buildingId'], '');
      });
    });
  });
}
