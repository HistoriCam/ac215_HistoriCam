import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';

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
        'Vision API URL not configured. Please update ApiConfig.visionApiUrl with your Cloud Run URL.'
      );
    }

    try {
      // Create multipart request
      final uri = Uri.parse(ApiConfig.identifyEndpoint);
      final request = http.MultipartRequest('POST', uri);

      // Use XFile for cross-platform compatibility (web + mobile)
      final xFile = XFile(imagePath);
      final bytes = await xFile.readAsBytes();
      final filename = xFile.name;

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

      // Add the image file with proper content type
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: filename,
          contentType: MediaType.parse(contentType),
        ),
      );

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Check response status
      if (response.statusCode == 200) {
        // Parse and return the JSON response
        return json.decode(response.body);
      } else {
        throw Exception(
          'API request failed with status ${response.statusCode}: ${response.body}'
        );
      }
    } catch (e) {
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

  /// Get a human-readable building name from building_id
  ///
  /// This is a placeholder - you'll want to implement a proper mapping
  /// from building IDs to full names, possibly from a database or API
  String getBuildingName(String buildingId) {
    // TODO: Implement proper building ID to name mapping
    // For now, just return the building ID formatted nicely
    return buildingId.replaceAll('_', ' ').split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Get a building description
  ///
  /// This is a placeholder - you'll want to fetch this from your backend
  /// or a database that contains building information
  String getBuildingDescription(String buildingId) {
    // TODO: Implement proper building description fetching
    // This could come from another API endpoint or local database
    return 'Information about $buildingId. This is a historic building with significant architectural and cultural importance.';
  }
}
