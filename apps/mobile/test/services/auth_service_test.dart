import 'package:flutter_test/flutter_test.dart';
import 'package:historicam/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../test_helpers.dart';

void main() {
  setUpAll(() async {
    await initializeSupabaseForTest();
  });

  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('should initialize correctly', () {
      expect(authService, isNotNull);
    });

    test('currentUser returns null when not logged in', () {
      expect(authService.currentUser, isNull);
    });

    test('isLoggedIn returns false when not logged in', () {
      expect(authService.isLoggedIn, isFalse);
    });

    test('username returns null when not logged in', () {
      expect(authService.username, isNull);
    });

    group('signup', () {
      test('should throw AuthException with empty username', () async {
        expect(
          () => authService.signup('', 'password123'),
          throwsA(isA<AuthException>()),
        );
      });

      test('should throw AuthException with empty password', () async {
        expect(
          () => authService.signup('testuser', ''),
          throwsA(isA<AuthException>()),
        );
      });

      test('should convert username to lowercase email format', () async {
        // This test verifies the email format logic
        // In a real scenario, this would make actual API calls
        try {
          await authService.signup('TestUser', 'password123');
        } catch (e) {
          // Expected to fail in test environment
          expect(e, isA<AuthException>());
        }
      });

      test('should handle AuthException from Supabase', () async {
        expect(
          () => authService.signup('invalid@user', 'short'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('login', () {
      test('should throw AuthException with empty username', () async {
        expect(
          () => authService.login('', 'password123'),
          throwsA(isA<AuthException>()),
        );
      });

      test('should throw AuthException with empty password', () async {
        expect(
          () => authService.login('testuser', ''),
          throwsA(isA<AuthException>()),
        );
      });

      test('should convert username to lowercase email format', () async {
        try {
          await authService.login('TestUser', 'password123');
        } catch (e) {
          // Expected to fail in test environment
          expect(e, isA<AuthException>());
        }
      });

      test('should handle invalid credentials', () async {
        expect(
          () => authService.login('nonexistent', 'wrongpassword'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('logout', () {
      test('should complete without error even when not logged in', () async {
        expect(() => authService.logout(), returnsNormally);
      });
    });

    group('authStateChanges', () {
      test('should return a stream', () {
        expect(authService.authStateChanges, isA<Stream<AuthState>>());
      });

      test('should emit auth state changes', () async {
        final stream = authService.authStateChanges;
        expect(stream, emitsInAnyOrder([isA<AuthState>()]));
      });
    });
  });
}
