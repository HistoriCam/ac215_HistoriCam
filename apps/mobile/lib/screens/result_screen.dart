import 'package:flutter/material.dart';
import 'dart:io';
import '../widgets/chatbot_widget.dart';

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

  @override
  void initState() {
    super.initState();
    _processImage();
  }

  Future<void> _processImage() async {
    // Simulate API call delay
    // TODO: Replace with actual Vision API call
    await Future.delayed(const Duration(seconds: 2));

    // Mock data - replace with actual API response
    setState(() {
      _buildingName = "Sander's Theatre";
      _buildingDescription = '''Inspired by Christopher Wren's Sheldonian Theatre at Oxford, England, Sanders Theatre is famous for its design and its acoustics. A member of the League of Historic American Theatres, the 1,000 seat theatre offers a unique and intimate 180 degree design which provides unusual proximity to the stage. The theatre was designed to function as a major lecture hall and as the site of college commencements. Although Sanders saw its last regularly scheduled Harvard College commencement exercise in 1922, and its final Radcliffe College commencement in 1957, the theatre continues to play a major role in the academic mission of Harvard College, hosting undergraduate core curriculum courses, the prestigious Charles Eliot Norton Lectures, and the annual Phi Beta Kappa induction ceremony. Many of the most venerable academic, political and literary figures of the nineteenth and twentieth century have taken the lectern at Sanders Theatre including Winston Churchill, Theodore Roosevelt, and Martin Luther King, Jr.''';
      _isLoading = false;
    });
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
          // Captured image
          _buildImageSection(),

          // Building information
          _buildInfoSection(),

          // Chatbot section
          ChatbotWidget(),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Image.file(
        File(widget.imagePath),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Building name
          Text(
            _buildingName,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B2B2B),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              _buildingDescription,
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Color(0xFF2B2B2B),
              ),
              textAlign: TextAlign.justify,
            ),
          ),

          const SizedBox(height: 24),

          // Tour suggestions button
          SizedBox(
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
                side: BorderSide(color: Color(0xFF2B2B2B), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Do want suggestions for a tour?',
                style: TextStyle(
                  color: Color(0xFF2B2B2B),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
