import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// LLM-RAG API Service for HistoriCam chatbot
///
/// Provides question-answering capabilities using RAG (Retrieval Augmented Generation)
class LlmRagService {
  /// Send a question to the LLM-RAG API
  ///
  /// Args:
  ///   question: The user's question
  ///   chunkType: Type of text chunking ('char-split' or 'recursive-split')
  ///   topK: Number of relevant documents to retrieve (default: 5)
  ///   returnDocs: Whether to return the retrieved documents (default: false)
  ///
  /// Returns:
  ///   Map containing 'answer' and optionally 'documents'
  ///
  /// Throws:
  ///   Exception if the API call fails
  Future<Map<String, dynamic>> askQuestion({
    required String question,
    String chunkType = 'recursive-split',
    int topK = 5,
    bool returnDocs = false,
  }) async {
    // Check if API is configured
    if (!ApiConfig.isLlmRagConfigured()) {
      throw Exception(
          'LLM-RAG API URL not configured. Please update ApiConfig.llmRagApiUrl.');
    }

    try {
      // Create request body
      final body = {
        'question': question,
        'chunk_type': chunkType,
        'top_k': topK,
        'return_docs': returnDocs,
      };

      // Send POST request
      final uri = Uri.parse(ApiConfig.chatEndpoint);
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      // Check response status
      if (response.statusCode == 200) {
        // Parse and return the JSON response
        return json.decode(response.body);
      } else {
        throw Exception(
            'API request failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error calling LLM-RAG API: $e');
    }
  }

  /// Parse the API response to extract the answer
  ///
  /// Args:
  ///   apiResponse: The raw API response map
  ///
  /// Returns:
  ///   The answer text, or an error message
  String parseAnswer(Map<String, dynamic> apiResponse) {
    try {
      final answer = apiResponse['answer'];
      if (answer != null && answer is String) {
        return answer;
      } else {
        return 'Sorry, I could not generate an answer to your question.';
      }
    } catch (e) {
      return 'Sorry, there was an error processing your question.';
    }
  }

  /// Get relevant documents from the API response (if returnDocs was true)
  ///
  /// Args:
  ///   apiResponse: The raw API response map
  ///
  /// Returns:
  ///   List of document maps, or empty list if none
  List<Map<String, dynamic>> parseDocuments(Map<String, dynamic> apiResponse) {
    try {
      final documents = apiResponse['documents'];
      if (documents != null && documents is List) {
        return List<Map<String, dynamic>>.from(
            documents.map((doc) => Map<String, dynamic>.from(doc)));
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
