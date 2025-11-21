import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool _supabaseInitialized = false;

/// Initialize Supabase for testing with a mock configuration
Future<void> initializeSupabaseForTest() async {
  // Only initialize once
  if (_supabaseInitialized) {
    return;
  }

  try {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key-for-testing-purposes-only',
    );
    _supabaseInitialized = true;
  } catch (e) {
    // If initialization fails, it might already be initialized
    // Check if we can access the instance
    try {
      final _ = Supabase.instance;
      _supabaseInitialized = true;
    } catch (_) {
      // Re-throw the original error if instance is not accessible
      rethrow;
    }
  }
}
