import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/chatbot_widget.dart';
import '../services/vision_api_service.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;

  const ResultScreen({super.key, required this.imagePath});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true;
  String _buildingName = '';
  String _buildingDescription = '';

  final VisionApiService _visionApi = VisionApiService();

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      // Call the vision API to identify the building
      final response = await _visionApi.identifyBuilding(widget.imagePath);

      // Parse the response
      final parsed = _visionApi.parseResponse(response);

      if (parsed['success'] == true) {
        // Successfully identified building
        final buildingId = parsed['buildingId'];
        final confidence = parsed['confidence'];
        final status = parsed['status'];

        setState(() {
          _buildingName = _visionApi.getBuildingName(buildingId);
          final baseDescription = _visionApi.getBuildingDescription(buildingId);

          // Add confidence info to description
          if (status == 'uncertain') {
            _buildingDescription =
                'Confidence: ${(confidence * 100).toStringAsFixed(1)}% (Low confidence - building might be nearby)\n\n$baseDescription';
          } else {
            _buildingDescription =
                'Confidence: ${(confidence * 100).toStringAsFixed(1)}%\n\n$baseDescription';
          }

          _isLoading = false;
        });
      } else {
        // Failed to identify building
        setState(() {
          _buildingName = "Building Not Found";
          _buildingDescription = parsed['message'] ??
              "We couldn't identify this building. It may not be in our database, or the image quality might be too low. Please try again with a clearer photo.";
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error calling vision API: $e');

      // Fallback to dummy data if API fails
      try {
        final String dummyData =
            await rootBundle.loadString('assets/dummy.txt');
        final List<String> lines = dummyData.split('\n');

        if (lines.length >= 2) {
          setState(() {
            _buildingName = lines[0].trim();
            _buildingDescription =
                'Note: Using cached data (API unavailable)\n\n${lines[1].trim()}';
            _isLoading = false;
          });
        } else {
          throw Exception('Invalid dummy data format');
        }
      } catch (dummyError) {
        // Complete fallback
        setState(() {
          _buildingName = "Connection Error";
          _buildingDescription =
              "Unable to connect to the vision service. Please check your internet connection and try again.\n\nError: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Scrollable content
            Expanded(
              child: _isLoading ? _buildLoadingState() : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: const Color(0xFFE63946),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HistoriCam',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Your Personal Tour Guide',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFE63946),
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing building...',
            style: TextStyle(
              color: Color(0xFF2B2B2B),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we identify the landmark',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Image and description side by side
          _buildImageAndDescriptionSection(),

          // Tour suggestions button
          _buildTourButton(),

          // Chatbot section
          ChatbotWidget(),
        ],
      ),
    );
  }

  Widget _buildImageAndDescriptionSection() {
    return SizedBox(
      height: 600, // Fixed height to avoid layout issues
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/dummy.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                );
              },
            ),
          ),

          // Description overlay on the right side
          Positioned(
            top: 40,
            right: 40,
            width: 450,
            height: 520, // Fixed height instead of using bottom constraint
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: const Color(0xFFD3D3D3).withOpacity(0.85),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Building name
                    Text(
                      _buildingName,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    Text(
                      _buildingDescription,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Color(0xFF000000),
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTourButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      color: const Color(0xFFF5EFE6),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () {
            // TODO: Implement tour suggestions
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tour suggestions coming soon!'),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: Color(0xFF2B2B2B), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            'Do want suggestions for a tour?',
            style: TextStyle(
              color: Color(0xFF2B2B2B),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
