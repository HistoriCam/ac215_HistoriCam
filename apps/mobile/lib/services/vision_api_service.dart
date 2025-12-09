import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../config/supabase_config.dart';

class VisionApiService {
  /// Identifies a building from an image file
  ///
  /// Args:
  ///   imagePath: Path to the image file (for mobile) or XFile path (for web)
  ///
  /// Returns:
  ///   Map containing the API response with building identification
  ///
  /// Throws:
  ///   Exception if the API call fails
  Future<Map<String, dynamic>> identifyBuilding(String imagePath) async {
    // Check if API is configured
    if (!ApiConfig.isConfigured()) {
      throw Exception(
          'Vision API URL not configured. Please update ApiConfig.visionApiUrl with your Cloud Run URL.');
    }

    try {
      print('VisionAPI: Starting image identification');
      print('VisionAPI: Image path: $imagePath');
      print('VisionAPI: API endpoint: ${ApiConfig.identifyEndpoint}');

      // Create multipart request
      final uri = Uri.parse(ApiConfig.identifyEndpoint);
      final request = http.MultipartRequest('POST', uri);

      // Use XFile for cross-platform compatibility (web + mobile)
      final xFile = XFile(imagePath);
      print('VisionAPI: Reading image bytes...');
      final bytes = await xFile.readAsBytes();
      final filename = xFile.name;
      print('VisionAPI: Image loaded - ${bytes.length} bytes, filename: $filename');

      // Determine content type from file extension
      String contentType = 'image/jpeg'; // default
      if (filename.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (filename.toLowerCase().endsWith('.jpg') ||
          filename.toLowerCase().endsWith('.jpeg')) {
        contentType = 'image/jpeg';
      } else if (filename.toLowerCase().endsWith('.webp')) {
        contentType = 'image/webp';
      }
      print('VisionAPI: Content type: $contentType');

      // Add the image file with proper content type
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: filename,
          contentType: MediaType.parse(contentType),
        ),
      );

      print('VisionAPI: Sending request to server...');
      // Send the request
      final streamedResponse = await request.send();
      print('VisionAPI: Received response with status: ${streamedResponse.statusCode}');
      final response = await http.Response.fromStream(streamedResponse);

      // Check response status
      if (response.statusCode == 200) {
        print('VisionAPI: Success! Parsing response...');
        // Parse and return the JSON response
        return json.decode(response.body);
      } else {
        print('VisionAPI: Request failed with status ${response.statusCode}');
        print('VisionAPI: Response body: ${response.body}');
        throw Exception(
            'API request failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('VisionAPI: ERROR - $e');
      throw Exception('Error calling vision API: $e');
    }
  }

  /// Parse the API response to extract building information
  ///
  /// Args:
  ///   apiResponse: The raw API response map
  ///
  /// Returns:
  ///   Map with 'name' and 'description' keys, or error information
  Map<String, dynamic> parseResponse(Map<String, dynamic> apiResponse) {
    try {
      final status = apiResponse['status'];
      final buildingId = apiResponse['building_id'];
      final confidence = apiResponse['confidence'];

      if (status == 'confident' || status == 'uncertain') {
        // Successfully identified building
        return {
          'success': true,
          'buildingId': buildingId,
          'confidence': confidence,
          'status': status,
          'message': apiResponse['message'],
          'matches': apiResponse['matches'],
        };
      } else if (status == 'no_match') {
        // No match found
        return {
          'success': false,
          'error': 'no_match',
          'message': apiResponse['message'] ?? 'No matching building found',
        };
      } else {
        // Unknown status
        return {
          'success': false,
          'error': 'unknown',
          'message': 'Unknown response status: $status',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'parse_error',
        'message': 'Failed to parse API response: $e',
      };
    }
  }

  /// Fetch building information from Supabase by building_id
  ///
  /// Args:
  ///   buildingId: The numeric building ID (as string)
  ///
  /// Returns:
  ///   Map containing 'name' and 'description' keys
  ///
  /// Throws:
  ///   Exception if the fetch fails
  Future<Map<String, String>> fetchBuildingInfo(String buildingId) async {
    try {
      // Convert buildingId to integer for querying
      final id = int.tryParse(buildingId);
      if (id == null) {
        throw Exception('Invalid building ID: $buildingId');
      }

      // Query Supabase for building information
      final uri = Uri.parse(
        '${SupabaseConfig.supabaseUrl}/rest/v1/building_descriptions?id=eq.$id&select=name,description',
      );

      final response = await http.get(
        uri,
        headers: {
          'apikey': SupabaseConfig.supabaseKey,
          'Authorization': 'Bearer ${SupabaseConfig.supabaseKey}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        if (data.isNotEmpty) {
          final building = data[0];
          return {
            'name': building['name'] ?? 'Unknown Building',
            'description':
                building['description'] ?? 'No description available.',
          };
        } else {
          // Building not found in database
          return {
            'name': 'Building $buildingId',
            'description': 'Information not available for this building.',
          };
        }
      } else {
        throw Exception(
            'Failed to fetch building info: ${response.statusCode}');
      }
    } catch (e) {
      // Return fallback data on error
      return {
        'name': 'Building $buildingId',
        'description': 'Error fetching building information: $e',
      };
    }
  }

  /// Get a human-readable building name from building_id
  ///
  /// This is deprecated - use fetchBuildingInfo instead
  @deprecated
  String getBuildingName(String buildingId) {
    return buildingId
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Get a building description
  ///
  /// This is deprecated - use fetchBuildingInfo instead
  @deprecated
  String getBuildingDescription(String buildingId) {
    return 'Information about $buildingId. This is a historic building with significant architectural and cultural importance.';
  }
}
