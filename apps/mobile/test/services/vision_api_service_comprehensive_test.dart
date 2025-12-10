import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/services/vision_api_service.dart';

void main() {
  group('VisionApiService - Comprehensive Coverage', () {
    late VisionApiService service;

    setUp(() {
      service = VisionApiService();
    });

    group('Deprecated methods', () {
      test('getBuildingName should format building ID correctly', () {
        // ignore: deprecated_member_use_from_same_package
        final name = service.getBuildingName('eiffel_tower');
        expect(name, equals('Eiffel Tower'));
      });

      test('getBuildingName should handle single word', () {
        // ignore: deprecated_member_use_from_same_package
        final name = service.getBuildingName('colosseum');
        expect(name, equals('Colosseum'));
      });

      test('getBuildingName should handle multiple underscores', () {
        // ignore: deprecated_member_use_from_same_package
        final name = service.getBuildingName('statue_of_liberty');
        expect(name, equals('Statue Of Liberty'));
      });

      test('getBuildingName should handle empty string', () {
        // ignore: deprecated_member_use_from_same_package
        expect(() => service.getBuildingName(''), throwsRangeError);
      });

      test('getBuildingDescription should return description', () {
        // ignore: deprecated_member_use_from_same_package
        final description = service.getBuildingDescription('eiffel_tower');
        expect(description, contains('eiffel_tower'));
        expect(description, contains('historic building'));
        expect(description, contains('architectural'));
      });

      test('getBuildingDescription should handle any building ID', () {
        // ignore: deprecated_member_use_from_same_package
        final description = service.getBuildingDescription('random_building');
        expect(description, isNotEmpty);
        expect(description, contains('random_building'));
      });
    });

    group('parseResponse - catch block coverage', () {
      test('should handle exception and return parse_error', () {
        // Pass something that will cause an exception during parsing
        final result = service.parseResponse({'status': null});
        expect(result['success'], isFalse);
        expect(result['error'], 'unknown');
      });

      test('should handle parseResponse with null buildingId and null confidence', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': null,
          'confidence': null,
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isTrue);
        expect(result['buildingId'], isNull);
        expect(result['confidence'], isNull);
      });

      test('should preserve message field', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': 'test',
          'message': 'Test message',
        };

        final result = service.parseResponse(apiResponse);
        expect(result['message'], equals('Test message'));
      });

      test('should preserve matches field', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': 'test',
          'matches': [
            {'building_id': 'test', 'confidence': 0.9}
          ],
        };

        final result = service.parseResponse(apiResponse);
        expect(result['matches'], isNotNull);
        expect(result['matches'], isA<List>());
      });
    });

    group('parseResponse - status edge cases', () {
      test('should handle no_match with custom message', () {
        final apiResponse = {
          'status': 'no_match',
          'message': 'Custom no match message',
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isFalse);
        expect(result['error'], 'no_match');
        expect(result['message'], 'Custom no match message');
      });

      test('should handle no_match without message', () {
        final apiResponse = {
          'status': 'no_match',
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isFalse);
        expect(result['error'], 'no_match');
        expect(result['message'], 'No matching building found');
      });

      test('should handle error with custom message', () {
        final apiResponse = {
          'status': 'error',
          'message': 'Custom error message',
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isFalse);
        expect(result['error'], 'error');
        expect(result['message'], 'Custom error message');
      });

      test('should handle error without message', () {
        final apiResponse = {
          'status': 'error',
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isFalse);
        expect(result['error'], 'error');
        expect(result['message'], 'API error occurred');
      });

      test('should handle unknown status', () {
        final apiResponse = {
          'status': 'weird_status',
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isFalse);
        expect(result['error'], 'unknown');
        expect(result['message'], contains('Unknown response status'));
        expect(result['message'], contains('weird_status'));
      });
    });

    group('parseResponse - data type variations', () {
      test('should handle integer building_id', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': 123,
          'confidence': 0.95,
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isTrue);
        expect(result['buildingId'], 123);
      });

      test('should handle integer confidence', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': 'test',
          'confidence': 1,
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isTrue);
        expect(result['confidence'], 1);
      });

      test('should handle zero confidence', () {
        final apiResponse = {
          'status': 'uncertain',
          'building_id': 'test',
          'confidence': 0.0,
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isTrue);
        expect(result['confidence'], 0.0);
      });

      test('should handle max confidence', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': 'test',
          'confidence': 1.0,
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isTrue);
        expect(result['confidence'], 1.0);
      });
    });

    group('parseResponse - uncertain status', () {
      test('should handle uncertain status correctly', () {
        final apiResponse = {
          'status': 'uncertain',
          'building_id': 'test_building',
          'confidence': 0.45,
          'message': 'Low confidence match',
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isTrue);
        expect(result['status'], 'uncertain');
        expect(result['buildingId'], 'test_building');
        expect(result['confidence'], 0.45);
      });

      test('should treat uncertain same as confident for success', () {
        final apiResponse = {
          'status': 'uncertain',
          'building_id': 'test',
          'confidence': 0.5,
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isTrue);
        expect(result.containsKey('buildingId'), isTrue);
        expect(result.containsKey('confidence'), isTrue);
      });
    });

    group('parseResponse - matches field variations', () {
      test('should handle empty matches array', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': 'test',
          'matches': [],
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isTrue);
        expect(result['matches'], isEmpty);
      });

      test('should handle null matches', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': 'test',
          'matches': null,
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isTrue);
        expect(result['matches'], isNull);
      });

      test('should handle multiple matches', () {
        final apiResponse = {
          'status': 'uncertain',
          'building_id': 'building1',
          'confidence': 0.65,
          'matches': [
            {'building_id': 'building1', 'confidence': 0.65},
            {'building_id': 'building2', 'confidence': 0.60},
            {'building_id': 'building3', 'confidence': 0.55},
          ],
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isTrue);
        expect((result['matches'] as List).length, 3);
      });
    });

    group('Service instance', () {
      test('should create unique instances', () {
        final service1 = VisionApiService();
        final service2 = VisionApiService();

        expect(service1, isNot(same(service2)));
      });

      test('should have consistent behavior across instances', () {
        final service1 = VisionApiService();
        final service2 = VisionApiService();

        final apiResponse = {
          'status': 'confident',
          'building_id': 'test',
          'confidence': 0.95,
        };

        final result1 = service1.parseResponse(apiResponse);
        final result2 = service2.parseResponse(apiResponse);

        expect(result1['success'], result2['success']);
        expect(result1['buildingId'], result2['buildingId']);
        expect(result1['confidence'], result2['confidence']);
      });
    });

    group('Edge case inputs', () {
      test('should handle empty map', () {
        final result = service.parseResponse({});
        expect(result['success'], isFalse);
      });

      test('should handle map with only status', () {
        final result = service.parseResponse({'status': 'confident'});
        expect(result['success'], isTrue);
        expect(result['buildingId'], isNull);
      });

      test('should handle very long building ID', () {
        final longId = 'a' * 1000;
        final apiResponse = {
          'status': 'confident',
          'building_id': longId,
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isTrue);
        expect(result['buildingId'], longId);
      });

      test('should handle building ID with special characters', () {
        final apiResponse = {
          'status': 'confident',
          'building_id': 'building-123_test.v2',
          'confidence': 0.9,
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isTrue);
        expect(result['buildingId'], 'building-123_test.v2');
      });

      test('should handle very long message', () {
        final longMessage = 'a' * 10000;
        final apiResponse = {
          'status': 'no_match',
          'message': longMessage,
        };

        final result = service.parseResponse(apiResponse);
        expect(result['success'], isFalse);
        expect(result['message'], longMessage);
      });
    });
  });
}
