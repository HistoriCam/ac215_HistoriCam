import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initialize Supabase for testing with a mock configuration
Future<void> initializeSupabaseForTest() async {
  // Only initialize if not already initialized
  try {
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key-for-testing-purposes-only',
    );
  } catch (e) {
    // Already initialized, ignore
  }
}
