import 'package:supabase_flutter/supabase_flutter.dart';

/// Authentication service for HistoriCam
///
/// Uses Supabase's built-in authentication system
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get current user session
  User? get currentUser => _supabase.auth.currentUser;

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Sign up a new user
  ///
  /// Args:
  ///   username: Desired username
  ///   password: User's password
  ///
  /// Returns:
  ///   AuthResponse with user data if successful
  ///
  /// Throws:
  ///   AuthException if signup fails
  Future<AuthResponse> signup(String username, String password) async {
    try {
      // Create a unique email from username for Supabase auth
      // Using .app domain which is valid for email addresses
      final email = '${username.toLowerCase()}@historicam.app';

      // Sign up with Supabase's built-in auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'display_name': username,
        },
      );

      if (response.user == null) {
        throw const AuthException('Signup failed - user not created');
      }

      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Signup failed: $e');
    }
  }

  /// Login with username and password
  ///
  /// Since we can't login by username directly, we need to find the user's email first
  /// This is a workaround - in production you'd want a better solution
  ///
  /// Args:
  ///   username: User's username
  ///   password: User's password
  ///
  /// Returns:
  ///   AuthResponse with user data if successful
  ///
  /// Throws:
  ///   AuthException if login fails
  Future<AuthResponse> login(String username, String password) async {
    try {
      // Sign in with the generated email format
      final email = '${username.toLowerCase()}@historicam.app';
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Login failed: $e');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  /// Get username from current session
  String? get username {
    return currentUser?.userMetadata?['username'] as String?;
  }

  /// Listen to authentication state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
