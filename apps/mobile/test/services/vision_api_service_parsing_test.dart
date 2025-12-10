import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/services/vision_api_service.dart';

void main() {
  group('VisionApiService - Response Parsing', () {
    late VisionApiService service;

    setUp(() {
      service = VisionApiService();
    });

    test('should initialize correctly', () {
      expect(service, isNotNull);
    });

    group('parseResponse - confident status', () {
      test('should parse confident response correctly', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': '123',
          'confidence': 0.95,
          'message': 'Building identified with high confidence',
          'matches': [
            {'id': '123', 'score': 0.95}
          ]
        };

        final result = service.parseResponse(apiResponse);

        expect(result['success'], isTrue);
        expect(result['buildingId'], equals('123'));
        expect(result['confidence'], equals(0.95));
        expect(result['status'], equals('confident'));
        expect(result['message'], isNotEmpty);
        expect(result['matches'], isNotNull);
      });

      test('should handle high confidence values', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': '456',
          'confidence': 0.99,
          'message': 'Very high confidence',
          'matches': []
        };

        final result = service.parseResponse(apiResponse);

        expect(result['success'], isTrue);
        expect(result['confidence'], equals(0.99));
        expect(result['confidence'], greaterThan(0.9));
      });
    });

    group('parseResponse - uncertain status', () {
      test('should parse uncertain response correctly', () {
        final apiResponse = {
          'status': 'uncertain',
          'building_id': '789',
          'confidence': 0.65,
          'message': 'Low confidence match',
          'matches': [
            {'id': '789', 'score': 0.65},
            {'id': '790', 'score': 0.62}
          ]
        };

        final result = service.parseResponse(apiResponse);

        expect(result['success'], isTrue);
        expect(result['buildingId'], equals('789'));
        expect(result['confidence'], equals(0.65));
        expect(result['status'], equals('uncertain'));
      });

      test('should handle borderline confidence values', () {
        final apiResponse = {
          'status': 'uncertain',
          'building_id': '100',
          'confidence': 0.50,
          'message': 'Borderline match',
          'matches': []
        };

        final result = service.parseResponse(apiResponse);

        expect(result['success'], isTrue);
        expect(result['confidence'], lessThan(0.7));
        expect(result['status'], equals('uncertain'));
      });
    });

    group('parseResponse - no_match status', () {
      test('should parse no_match response correctly', () {
        final apiResponse = {
          'status': 'no_match',
          'message': 'No matching building found in database',
        };

        final result = service.parseResponse(apiResponse);

        expect(result['success'], isFalse);
        expect(result['error'], equals('no_match'));
        expect(result['message'], contains('No matching building'));
      });

      test('should provide default message when missing', () {
        final apiResponse = {
          'status': 'no_match',
        };

        final result = service.parseResponse(apiResponse);

        expect(result['success'], isFalse);
        expect(result['error'], equals('no_match'));
        expect(result['message'], equals('No matching building found'));
      });
    });

    group('parseResponse - error cases', () {
      test('should handle unknown status', () {
        final apiResponse = {
          'status': 'invalid_status',
          'building_id': '123',
        };

        final result = service.parseResponse(apiResponse);

        expect(result['success'], isFalse);
        expect(result['error'], equals('unknown'));
        expect(result['message'], contains('Unknown response status'));
      });

      test('should handle missing status field', () {
        final apiResponse = {
          'building_id': '123',
          'confidence': 0.95,
        };

        final result = service.parseResponse(apiResponse);

        expect(result['success'], isFalse);
        expect(result['error'], equals('unknown'));
        expect(result['message'], contains('Unknown response status'));
      });

      test('should handle empty response', () {
        final apiResponse = <String, dynamic>{};

        final result = service.parseResponse(apiResponse);

        expect(result['success'], isFalse);
        expect(result['error'], equals('unknown'));
        expect(result['message'], contains('Unknown response status'));
      });

      test('should handle malformed response gracefully', () {
        final apiResponse = {
          'status': 'confident',
          // Missing required fields
        };

        final result = service.parseResponse(apiResponse);

        expect(result['success'], isTrue);
        expect(result['buildingId'], isNull);
        expect(result['confidence'], isNull);
      });
    });

    group('parseResponse - data types', () {
      test('should handle string building_id', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': '999',
          'confidence': 0.85,
          'message': 'test',
          'matches': []
        };

        final result = service.parseResponse(apiResponse);

        expect(result['buildingId'], isA<String>());
        expect(result['buildingId'], equals('999'));
      });

      test('should handle numeric confidence', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': '123',
          'confidence': 0.75,
          'message': 'test',
          'matches': []
        };

        final result = service.parseResponse(apiResponse);

        expect(result['confidence'], isA<num>());
        expect(result['confidence'], equals(0.75));
      });

      test('should handle integer confidence', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': '123',
          'confidence': 1,
          'message': 'test',
          'matches': []
        };

        final result = service.parseResponse(apiResponse);

        expect(result['confidence'], equals(1));
      });

      test('should preserve matches array', () {
        final matches = [
          {'id': '1', 'score': 0.9},
          {'id': '2', 'score': 0.8}
        ];
        final apiResponse = {
          'status': 'confident',
          'building_id': '1',
          'confidence': 0.9,
          'message': 'test',
          'matches': matches
        };

        final result = service.parseResponse(apiResponse);

        expect(result['matches'], equals(matches));
        expect(result['matches'], hasLength(2));
      });
    });

    group('parseResponse - edge cases', () {
      test('should handle null values in response', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': null,
          'confidence': null,
          'message': null,
          'matches': null
        };

        final result = service.parseResponse(apiResponse);

        expect(result['success'], isTrue);
        expect(result['buildingId'], isNull);
        expect(result['confidence'], isNull);
      });

      test('should handle extra fields in response', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': '123',
          'confidence': 0.9,
          'message': 'test',
          'matches': [],
          'extra_field_1': 'value1',
          'extra_field_2': 123,
          'nested': {'key': 'value'}
        };

        final result = service.parseResponse(apiResponse);

        expect(result['success'], isTrue);
        expect(result['buildingId'], equals('123'));
      });

      test('should handle very long messages', () {
        final longMessage = 'a' * 10000;
        final apiResponse = {
          'status': 'no_match',
          'message': longMessage,
        };

        final result = service.parseResponse(apiResponse);

        expect(result['success'], isFalse);
        expect(result['message'], equals(longMessage));
      });

      test('should handle special characters in message', () {
        final apiResponse = {
          'status': 'no_match',
          'message': 'Message with "quotes", \'apostrophes\', and émojis 🏛️',
        };

        final result = service.parseResponse(apiResponse);

        expect(result['message'], contains('quotes'));
        expect(result['message'], contains('émojis'));
        expect(result['message'], contains('🏛️'));
      });
    });

    group('parseResponse - multiple statuses', () {
      test('should prioritize confident over other statuses', () {
        final responses = [
          {'status': 'confident', 'building_id': '1', 'confidence': 0.95, 'message': 'test', 'matches': []},
          {'status': 'uncertain', 'building_id': '2', 'confidence': 0.65, 'message': 'test', 'matches': []},
        ];

        for (var response in responses) {
          final result = service.parseResponse(response);
          expect(result['status'], equals(response['status']));
        }
      });
    });

    group('Service instance behavior', () {
      test('should parse consistently across multiple calls', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': '123',
          'confidence': 0.9,
          'message': 'test',
          'matches': []
        };

        final result1 = service.parseResponse(apiResponse);
        final result2 = service.parseResponse(apiResponse);

        expect(result1['success'], equals(result2['success']));
        expect(result1['buildingId'], equals(result2['buildingId']));
        expect(result1['confidence'], equals(result2['confidence']));
      });

      test('should handle multiple service instances', () {
        final service2 = VisionApiService();
        final apiResponse = {
          'status': 'confident',
          'building_id': '123',
          'confidence': 0.9,
          'message': 'test',
          'matches': []
        };

        final result1 = service.parseResponse(apiResponse);
        final result2 = service2.parseResponse(apiResponse);

        expect(result1['success'], equals(result2['success']));
      });
    });
  });
}
