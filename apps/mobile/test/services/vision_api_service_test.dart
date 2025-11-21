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
  });
}
