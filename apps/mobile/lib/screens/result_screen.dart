import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/chatbot_widget.dart';
import '../services/vision_api_service.dart';
import '../services/search_history_service.dart';

class ResultScreen extends StatefulWidget {
  final String? imagePath;
  final int? buildingId;
  final String? buildingName;

  const ResultScreen({
    super.key,
    this.imagePath,
    this.buildingId,
    this.buildingName,
  }) : assert(imagePath != null || buildingId != null,
            'Either imagePath or buildingId must be provided');

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _buildingName = '';
  String _buildingDescription = '';
  String _displayedDescription = '';
  int _currentCharIndex = 0;

  final VisionApiService _visionApi = VisionApiService();
  SearchHistoryService? _historyService;

  @override
  void initState() {
    super.initState();
    if (widget.buildingId != null) {
      _loadBuildingFromHistory();
    } else {
      _processImage();
    }
  }

  void _startTypingAnimation() {
    if (_currentCharIndex < _buildingDescription.length) {
      Future.delayed(const Duration(milliseconds: 20), () {
        if (mounted) {
          setState(() {
            _currentCharIndex++;
            _displayedDescription =
                _buildingDescription.substring(0, _currentCharIndex);
          });
          _startTypingAnimation();
        }
      });
    }
  }

  Future<void> _loadBuildingFromHistory() async {
    try {
      // Load building info directly from building ID
      final buildingInfo = await _visionApi.fetchBuildingInfo(widget.buildingId.toString());

      setState(() {
        _buildingName = widget.buildingName ?? buildingInfo['name']!;
        _buildingDescription = buildingInfo['description']!;
        _isLoading = false;
        _currentCharIndex = 0;
        _displayedDescription = '';
      });
      _startTypingAnimation();
    } catch (e) {
      setState(() {
        _buildingName = widget.buildingName ?? 'Building #${widget.buildingId}';
        _buildingDescription = 'Error loading building information: $e';
        _isLoading = false;
        _currentCharIndex = 0;
        _displayedDescription = '';
      });
      _startTypingAnimation();
    }
  }

  Future<void> _processImage() async {
    try {
      // Call the vision API to identify the building
      final response = await _visionApi.identifyBuilding(widget.imagePath!);

      // Parse the response
      final parsed = _visionApi.parseResponse(response);

      if (parsed['success'] == true) {
        // Successfully identified building
        final buildingId = parsed['buildingId'];
        final confidence = parsed['confidence'];
        final status = parsed['status'];

        // Fetch building information from Supabase
        final buildingInfo = await _visionApi.fetchBuildingInfo(buildingId);

        // Save search to history
        try {
          final buildingIdInt = int.tryParse(buildingId);
          if (buildingIdInt != null) {
            _historyService ??= SearchHistoryService();
            await _historyService!.saveSearch(buildingIdInt);
          }
        } catch (e) {
          // Log error but don't block the UI
          debugPrint('Failed to save search history: $e');
        }

        setState(() {
          _buildingName = buildingInfo['name']!;
          final baseDescription = buildingInfo['description']!;

          // Add confidence info to description
          if (status == 'uncertain') {
            _buildingDescription =
                'Confidence: ${(confidence * 100).toStringAsFixed(1)}% (Low confidence - building might be nearby)\n\n$baseDescription';
          } else {
            _buildingDescription =
                'Confidence: ${(confidence * 100).toStringAsFixed(1)}%\n\n$baseDescription';
          }

          _isLoading = false;
          _currentCharIndex = 0;
          _displayedDescription = '';
        });
        _startTypingAnimation();
      } else {
        // Failed to identify building
        setState(() {
          _buildingName = "Building Not Found";
          _buildingDescription = parsed['message'] ??
              "We couldn't identify this building. It may not be in our database, or the image quality might be too low. Please try again with a clearer photo.";
          _isLoading = false;
          _currentCharIndex = 0;
          _displayedDescription = '';
        });
        _startTypingAnimation();
      }
    } catch (e) {
      debugPrint('Error calling vision API: $e');

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
            _currentCharIndex = 0;
            _displayedDescription = '';
          });
          _startTypingAnimation();
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
          _currentCharIndex = 0;
          _displayedDescription = '';
        });
        _startTypingAnimation();
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

          // Tour suggestions button (always visible)
          _buildTourButton(),

          // Chatbot section (always visible)
          ChatbotWidget(
            initialContext: _buildingDescription,
          ),
        ],
      ),
    );
  }

  Widget _buildImageAndDescriptionSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600; // Tablet breakpoint

    return Column(
      children: [
        // Image section
        Container(
          height: isPhone ? 400 : 500,
          width: double.infinity,
          child: widget.imagePath != null
              ? (kIsWeb
                  ? Image.network(
                      widget.imagePath!,
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
                    )
                  : Image.file(
                      File(widget.imagePath!),
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
                    ))
              : Image.asset(
                  'assets/images/dummy.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: Icon(
                          Icons.history,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Description section below image
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: const BoxDecoration(
            color: Color(0xFFF5EFE6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Building name
              Text(
                _buildingName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B2B2B),
                ),
              ),
              const SizedBox(height: 16),

              // Description with typing animation
              Text(
                _displayedDescription,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Color(0xFF2B2B2B),
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTourButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPhone = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 20 : 32,
        vertical: isPhone ? 16 : 24,
      ),
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
            padding: EdgeInsets.symmetric(vertical: isPhone ? 14 : 16),
            side: const BorderSide(color: Color(0xFF2B2B2B), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Text(
            'Do want suggestions for a tour?',
            style: TextStyle(
              color: const Color(0xFF2B2B2B),
              fontSize: isPhone ? 14 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
