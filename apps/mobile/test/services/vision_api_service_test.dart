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
    });
  });
}
