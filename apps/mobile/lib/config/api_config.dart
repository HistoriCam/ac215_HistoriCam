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
  /// For local testing, you can use: http://10.0.2.2:8080 (Android emulator)
  /// or http://localhost:8080 (iOS simulator)
  static const String visionApiUrl = 'YOUR_CLOUD_RUN_URL';

  /// Validate that the API URL has been configured
  static bool isConfigured() {
    return visionApiUrl != 'YOUR_CLOUD_RUN_URL' &&
           visionApiUrl.isNotEmpty;
  }

  /// Get the full identify endpoint URL
  static String get identifyEndpoint => '$visionApiUrl/identify';

  /// Get the health check endpoint URL
  static String get healthEndpoint => '$visionApiUrl/';
}
