// import 'package:firebase_auth/firebase_auth.dart';  // Disabled for iOS
// import 'package:cloud_firestore/cloud_firestore.dart';  // Disabled for iOS
import '../../domain/entities/user_entity.dart';
import '../../../../core/platform/platform_service.dart';
// import 'firebase_auth_repository_impl.dart';  // SDK-based, not used on iOS
import 'firebase_rest_auth_repository.dart';

/// Unified auth repository that uses REST API for iOS
class UnifiedAuthRepository {
  final FirebaseRestAuthRepository _restAPI;

  // Cache for current user (updated on sign in/sign up)
  UserEntity? _cachedUser;
  bool _initialized = false;

  UnifiedAuthRepository({
    dynamic firebaseAuth,  // Not used on iOS
    dynamic firestore,     // Not used on iOS
  })  : _restAPI = FirebaseRestAuthRepository();

  /// Initialize repository and restore session from storage
  Future<void> init() async {
    if (_initialized) return;

    print('🔵 [UNIFIED AUTH] Initializing...');
    await _restAPI.init();
    _cachedUser = _restAPI.getCurrentUser();
    _initialized = true;

    if (_cachedUser != null) {
      print('🟢 [UNIFIED AUTH] Session restored: ${_cachedUser!.email}');
    } else {
      print('🔵 [UNIFIED AUTH] No session found');
    }
  }

  Future<UserEntity?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    print('📱 [UNIFIED AUTH] Using REST API (iOS)');
    _cachedUser = await _restAPI.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _cachedUser;
  }

  Future<UserEntity?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    print('📱 [UNIFIED AUTH] Using REST API (iOS)');
    _cachedUser = await _restAPI.signUpWithEmailAndPassword(
      email: email,
      password: password,
      fullName: fullName,
    );
    return _cachedUser;
  }

  Future<void> signOut() async {
    _cachedUser = null;
    await _restAPI.signOut();
  }

  Future<UserEntity?> getCurrentUser() async {
    // Initialize if not already done (restore session from storage)
    try {
      await init();
    } catch (e) {
      print('⚠️ [UNIFIED AUTH] Error during init: $e');
      // If init fails, clear any partial state and return null
      _cachedUser = null;
      return null;
    }

    if (_cachedUser != null) {
      return _cachedUser;
    }

    _cachedUser = _restAPI.getCurrentUser();

    // If we have tokens but no valid user, session is corrupted
    if (_cachedUser == null && _restAPI.isSignedIn()) {
      print('⚠️ [UNIFIED AUTH] Invalid session detected, signing out');
      try {
        await signOut();
      } catch (e) {
        print('⚠️ [UNIFIED AUTH] Error during signout: $e');
      }
    }

    return _cachedUser;
  }

  // Synchronous version that returns cached user
  UserEntity? getCurrentUserSync() {
    return _cachedUser;
  }

  Future<bool> isSignedIn() async {
    return _restAPI.isSignedIn();
  }

  Future<String?> getCurrentUserId() async {
    final user = await getCurrentUser();
    return user?.id;
  }

  // Synchronous version using cache
  String? getCurrentUserIdSync() {
    return _cachedUser?.id;
  }

  Future<UserEntity> updateProfile({
    String? fullName,
    String? languagePreference,
  }) async {
    throw UnimplementedError('updateProfile not implemented for REST API yet');
  }

  Future<void> resetPassword(String email) async {
    throw UnimplementedError('resetPassword not implemented for REST API yet');
  }

  String? getIdToken() {
    return _restAPI.getIdToken();
  }
}
