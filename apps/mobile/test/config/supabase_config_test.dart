import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/config/supabase_config.dart';

void main() {
  group('SupabaseConfig', () {
    test('should have supabase URL defined', () {
      expect(SupabaseConfig.supabaseUrl, isNotEmpty);
      expect(SupabaseConfig.supabaseUrl, contains('supabase.co'));
    });

    test('should have correct Supabase URL', () {
      expect(SupabaseConfig.supabaseUrl,
          equals('https://mtsdyzpgwfbcimcendmn.supabase.co'));
    });

    test('supabaseUrl should start with https', () {
      expect(SupabaseConfig.supabaseUrl.startsWith('https://'), isTrue);
    });

    test('isConfigured should return false when key is empty', () {
      // In test environment, SUPABASE_KEY is not set, so it defaults to ''
      expect(SupabaseConfig.supabaseKey, isEmpty);

      // Call isConfigured - it will return false since key is empty
      // Note: This triggers an assertion in debug mode, but returns false
      bool result = false;
      try {
        result = SupabaseConfig.isConfigured();
      } catch (e) {
        // Assertions are enabled in tests, so this is expected
        result = false;
      }
      expect(result, isFalse);
    });

    test('supabaseKey should have a default value', () {
      // The key will be empty in tests since we don't pass --dart-define
      expect(SupabaseConfig.supabaseKey, isNotNull);
    });

    test('supabaseUrl should be a const', () {
      const url1 = SupabaseConfig.supabaseUrl;
      const url2 = SupabaseConfig.supabaseUrl;
      expect(url1, equals(url2));
    });

    test('supabaseKey should be a const', () {
      const key1 = SupabaseConfig.supabaseKey;
      const key2 = SupabaseConfig.supabaseKey;
      expect(key1, equals(key2));
    });
  });
}
