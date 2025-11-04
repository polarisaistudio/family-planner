import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/platform/platform_service.dart';
import 'firebase_auth_repository_impl.dart';
import 'firebase_rest_auth_repository.dart';

/// Unified auth repository that uses Firebase SDK or REST API based on platform
class UnifiedAuthRepository {
  final FirebaseAuthRepositoryImpl? _firebaseSDK;
  final FirebaseRestAuthRepository? _restAPI;

  // Cache for current user (updated on sign in/sign up)
  UserEntity? _cachedUser;

  UnifiedAuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseSDK = PlatformService.useFirebaseSDK && firebaseAuth != null && firestore != null
            ? FirebaseAuthRepositoryImpl(firebaseAuth, firestore)
            : null,
        _restAPI = PlatformService.useRestApi ? FirebaseRestAuthRepository() : null;

  Future<UserEntity?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    if (PlatformService.useRestApi) {
      print('📱 [UNIFIED AUTH] Using REST API (iOS)');
      _cachedUser = await _restAPI!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _cachedUser;
    } else {
      print('🌐 [UNIFIED AUTH] Using Firebase SDK (Web/Android)');
      _cachedUser = await _firebaseSDK!.signIn(
        email: email,
        password: password,
      );
      return _cachedUser;
    }
  }

  Future<UserEntity?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (PlatformService.useRestApi) {
      print('📱 [UNIFIED AUTH] Using REST API (iOS)');
      _cachedUser = await _restAPI!.signUpWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
      );
      return _cachedUser;
    } else {
      print('🌐 [UNIFIED AUTH] Using Firebase SDK (Web/Android)');
      _cachedUser = await _firebaseSDK!.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      return _cachedUser;
    }
  }

  Future<void> signOut() async {
    _cachedUser = null;
    if (PlatformService.useRestApi) {
      await _restAPI!.signOut();
    } else {
      await _firebaseSDK!.signOut();
    }
  }

  Future<UserEntity?> getCurrentUser() async {
    if (_cachedUser != null) {
      return _cachedUser;
    }

    if (PlatformService.useRestApi) {
      _cachedUser = _restAPI!.getCurrentUser();
      return _cachedUser;
    } else {
      _cachedUser = await _firebaseSDK!.getCurrentUser();
      return _cachedUser;
    }
  }

  // Synchronous version that returns cached user
  UserEntity? getCurrentUserSync() {
    return _cachedUser;
  }

  Future<bool> isSignedIn() async {
    if (PlatformService.useRestApi) {
      return _restAPI!.isSignedIn();
    } else {
      return await _firebaseSDK!.isAuthenticated();
    }
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
    if (PlatformService.useRestApi) {
      throw UnimplementedError('updateProfile not implemented for REST API yet');
    } else {
      return await _firebaseSDK!.updateProfile(
        fullName: fullName,
        languagePreference: languagePreference,
      );
    }
  }

  Future<void> resetPassword(String email) async {
    if (PlatformService.useRestApi) {
      throw UnimplementedError('resetPassword not implemented for REST API yet');
    } else {
      return await _firebaseSDK!.resetPassword(email);
    }
  }

  String? getIdToken() {
    if (PlatformService.useRestApi) {
      return _restAPI!.getIdToken();
    } else {
      // For Firebase SDK, we'd need to get the token differently
      // For now, return null as SDK handles auth internally
      return null;
    }
  }
}
