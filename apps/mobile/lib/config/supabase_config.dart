/// Supabase Configuration for HistoriCam
///
/// For local development:
/// 1. Create a file: secrets/supabase_key.txt
/// 2. Paste your Supabase anon key in that file
/// 3. Run: flutter run --dart-define-from-file=secrets/supabase_key.env
///
/// For production deployment (Vercel):
/// 1. Add SUPABASE_KEY as environment variable in Vercel dashboard
/// 2. The key will be injected at build time
class SupabaseConfig {
  /// Supabase project URL
  static const String supabaseUrl = 'https://mtsdyzpgwfbcimcendmn.supabase.co';

  /// Supabase anonymous key (injected at runtime)
  /// For local dev: passed via --dart-define
  /// For production: passed via environment variable
  static const String supabaseKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: '',
  );

  /// Validate that Supabase is properly configured
  static bool isConfigured() {
    if (supabaseKey.isEmpty) {
      // Using assert instead of print for configuration errors
      // This will only show in debug mode
      assert(false, 'SUPABASE_KEY not configured! '
          'For local dev: flutter run --dart-define-from-file=secrets/supabase_key.env '
          'For production: Set SUPABASE_KEY in Vercel environment variables');
      return false;
    }
    return true;
  }
}
