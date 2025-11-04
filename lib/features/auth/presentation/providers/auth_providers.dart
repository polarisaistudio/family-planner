import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/firebase_auth_repository_impl.dart';
import '../../data/repositories/unified_auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/platform/platform_service.dart';

/// Provider for Firebase Auth instance (only used on Web/Android)
final firebaseAuthProvider = Provider<FirebaseAuth?>((ref) {
  return PlatformService.useFirebaseSDK ? FirebaseAuth.instance : null;
});

/// Provider for Firestore instance (only used on Web/Android)
final firestoreProvider = Provider<FirebaseFirestore?>((ref) {
  return PlatformService.useFirebaseSDK ? FirebaseFirestore.instance : null;
});

/// Provider for Unified Auth Repository (uses REST on iOS, SDK elsewhere)
final unifiedAuthRepositoryProvider = Provider<UnifiedAuthRepository>((ref) {
  return UnifiedAuthRepository(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

/// Provider for current user state
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, AsyncValue<UserEntity?>>((ref) {
  return CurrentUserNotifier(ref.watch(unifiedAuthRepositoryProvider));
});

/// Notifier for managing current user state
class CurrentUserNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final UnifiedAuthRepository _authRepository;

  CurrentUserNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await _authRepository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName ?? '',
      );
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Update profile
  Future<void> updateProfile({
    String? fullName,
    String? languagePreference,
  }) async {
    try {
      final user = await _authRepository.updateProfile(
        fullName: fullName,
        languagePreference: languagePreference,
      );
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _authRepository.resetPassword(email);
  }
}

/// Provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final userState = ref.watch(currentUserProvider);
  return userState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});
