/// API Configuration for HistoriCam
///
/// Update the visionApiUrl with your deployed Cloud Run URL
class ApiConfig {
  /// Vision API base URL
  ///
  /// Instructions to get your Cloud Run URL:
  /// 1. Deploy your vision service to Cloud Run using deploy-cloud-run.sh
  /// 2. Copy the URL from the deployment output (format: https://vision-service-xxxxx-uc.a.run.app)
  /// 3. Replace the value below with your URL (do NOT include trailing slash)
  ///
  /// For local testing:
  /// - iOS simulator: http://localhost:8080
  /// - Android emulator: http://10.0.2.2:8080
  // static const String visionApiUrl = 'http://localhost:8080';
  static const String visionApiUrl = 'https://35.224.247.219.sslip.io/vision';

  /// LLM-RAG API base URL
  ///
  /// For local testing:
  /// - iOS simulator: http://localhost:8001
  /// - Android emulator: http://10.0.2.2:8001
  /// - Web: http://localhost:8001
  ///
  /// For production, update with your deployed URL
  // static const String llmRagApiUrl = 'http://localhost:8001';
  static const String llmRagApiUrl = 'https://35.224.247.219.sslip.io/llm';

  /// Validate that the API URL has been configured
  static bool isConfigured() {
    // Allow localhost for local testing
    if (visionApiUrl == 'http://localhost:8080' ||
        visionApiUrl == 'http://10.0.2.2:8080') {
      return true;
    }
    // For production, ensure it's a valid Cloud Run URL
    return visionApiUrl.isNotEmpty && visionApiUrl.startsWith('http');
  }

  /// Validate that the LLM-RAG API URL has been configured
  static bool isLlmRagConfigured() {
    // Allow localhost for local testing
    if (llmRagApiUrl == 'http://localhost:8001' ||
        llmRagApiUrl == 'http://10.0.2.2:8001') {
      return true;
    }
    // For production, ensure it's a valid URL
    return llmRagApiUrl.isNotEmpty && llmRagApiUrl.startsWith('http');
  }

  /// Get the full identify endpoint URL
  static String get identifyEndpoint => '$visionApiUrl/identify';

  /// Get the health check endpoint URL
  static String get healthEndpoint => '$visionApiUrl/';

  /// Get the LLM-RAG chat endpoint URL
  static String get chatEndpoint => '$llmRagApiUrl/chat';
}
