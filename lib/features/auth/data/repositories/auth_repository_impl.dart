import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Concrete implementation of AuthRepository using Supabase
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  AuthRepositoryImpl(this._supabase);

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      print('🔵 [AUTH] Starting sign up for email: $email');
      print('🔵 [AUTH] Full name: $fullName');

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      print('🔵 [AUTH] Sign up response received');
      print('🔵 [AUTH] User ID: ${response.user?.id}');
      print('🔵 [AUTH] User email: ${response.user?.email}');

      if (response.user == null) {
        print('🔴 [AUTH] Error: No user returned from sign up');
        throw Exception('Sign up failed: No user returned');
      }

      print('🔵 [AUTH] Fetching user profile from users table...');

      // Wait a moment for the database trigger to create the user profile
      await Future.delayed(const Duration(milliseconds: 500));

      // Fetch user profile from users table
      final userProfile = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      print('🟢 [AUTH] User profile fetched successfully: $userProfile');
      return UserModel.fromJson(userProfile);
    } on AuthException catch (e) {
      print('🔴 [AUTH] AuthException: ${e.message}');
      print('🔴 [AUTH] Status code: ${e.statusCode}');
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      print('🔴 [AUTH] Generic error: $e');
      print('🔴 [AUTH] Error type: ${e.runtimeType}');
      throw Exception('Sign up failed: $e');
    }
  }

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 [AUTH] Starting sign in for email: $email');

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      print('🔵 [AUTH] Sign in response received');
      print('🔵 [AUTH] User ID: ${response.user?.id}');

      if (response.user == null) {
        print('🔴 [AUTH] Error: No user returned from sign in');
        throw Exception('Sign in failed: No user returned');
      }

      print('🔵 [AUTH] Fetching user profile from users table...');

      // Fetch user profile from users table
      final userProfile = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      print('🟢 [AUTH] Sign in successful: $userProfile');
      return UserModel.fromJson(userProfile);
    } on AuthException catch (e) {
      print('🔴 [AUTH] AuthException: ${e.message}');
      print('🔴 [AUTH] Status code: ${e.statusCode}');
      throw Exception('Sign in failed: ${e.message}');
    } catch (e) {
      print('🔴 [AUTH] Generic error: $e');
      print('🔴 [AUTH] Error type: ${e.runtimeType}');
      throw Exception('Sign in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      throw Exception('Sign out failed: ${e.message}');
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final userProfile =
          await _supabase.from('users').select().eq('id', user.id).single();

      return UserModel.fromJson(userProfile);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? languagePreference,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (languagePreference != null) {
        updates['language_preference'] = languagePreference;
      }
      updates['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('users')
          .update(updates)
          .eq('id', user.id)
          .select()
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      throw Exception('Update profile failed: $e');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _supabase.auth.currentUser != null;
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw Exception('Password reset failed: ${e.message}');
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.asyncMap((state) async {
      final user = state.session?.user;
      if (user == null) return null;

      try {
        final userProfile =
            await _supabase.from('users').select().eq('id', user.id).single();
        return UserModel.fromJson(userProfile);
      } catch (e) {
        return null;
      }
    });
  }
}
