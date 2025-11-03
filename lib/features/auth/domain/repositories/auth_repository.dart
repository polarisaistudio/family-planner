import '../entities/user_entity.dart';

/// Abstract repository interface for authentication operations
abstract class AuthRepository {
  /// Sign up with email and password
  Future<UserEntity> signUp({
    required String email,
    required String password,
    String? fullName,
  });

  /// Sign in with email and password
  Future<UserEntity> signIn({
    required String email,
    required String password,
  });

  /// Sign out current user
  Future<void> signOut();

  /// Get current authenticated user
  Future<UserEntity?> getCurrentUser();

  /// Update user profile
  Future<UserEntity> updateProfile({
    String? fullName,
    String? languagePreference,
  });

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Reset password
  Future<void> resetPassword(String email);

  /// Stream of authentication state changes
  Stream<UserEntity?> get authStateChanges;
}
