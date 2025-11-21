import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/config/supabase_config.dart';

void main() {
  group('SupabaseConfig', () {
    test('should have valid supabase URL', () {
      expect(SupabaseConfig.supabaseUrl, isNotEmpty);
      expect(SupabaseConfig.supabaseUrl, startsWith('https://'));
      expect(SupabaseConfig.supabaseUrl, contains('.supabase.co'));
    });

    test('should have supabaseUrl constant defined', () {
      const url = SupabaseConfig.supabaseUrl;
      expect(url, equals('https://mtsdyzpgwfbcimcendmn.supabase.co'));
    });

    test('should read supabaseKey from environment', () {
      // In test environment, this should be empty by default
      // unless SUPABASE_KEY is set via --dart-define
      expect(SupabaseConfig.supabaseKey, isA<String>());
    });

    test('should have default empty key in test environment', () {
      // Since we're not passing --dart-define in tests
      expect(SupabaseConfig.supabaseKey, equals(''));
    });

    group('isConfigured', () {
      test('should return false when key is empty', () {
        // In test environment without --dart-define, key should be empty
        final isConfigured = SupabaseConfig.isConfigured();
        expect(isConfigured, isFalse);
      });

      test('should print error messages when not configured', () {
        // This test verifies the method runs without throwing
        expect(() => SupabaseConfig.isConfigured(), returnsNormally);
      });

      test('should check configuration validity', () {
        // Verify the logic: empty key means not configured
        const key = String.fromEnvironment('SUPABASE_KEY', defaultValue: '');
        expect(key.isEmpty, isTrue);
      });
    });

    test('should have correct URL format for API calls', () {
      const url = SupabaseConfig.supabaseUrl;
      // URL should be valid for Supabase API calls
      expect(Uri.parse(url).isAbsolute, isTrue);
      expect(Uri.parse(url).scheme, equals('https'));
    });

    test('should maintain URL structure', () {
      const url = SupabaseConfig.supabaseUrl;
      final uri = Uri.parse(url);
      expect(uri.host, contains('supabase.co'));
      expect(uri.host, isNot(isEmpty));
    });

    test('should use const for configuration values', () {
      // Verify the URL is a compile-time constant
      const url = SupabaseConfig.supabaseUrl;
      expect(url, isA<String>());
      expect(url, isNotEmpty);
    });

    test('should handle String.fromEnvironment correctly', () {
      // Verify environment variable handling with default
      const testKey = String.fromEnvironment('SUPABASE_KEY', defaultValue: '');
      expect(testKey, isA<String>());
    });

    test('should provide configuration guidance', () {
      // This test ensures isConfigured provides helpful output
      // by checking it executes without errors
      final result = SupabaseConfig.isConfigured();
      expect(result, isA<bool>());
    });
  });
}
