import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/firebase_auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Provider for Firebase Auth instance
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepositoryImpl(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

/// Provider for current user state
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, AsyncValue<UserEntity?>>((ref) {
  return CurrentUserNotifier(ref.watch(authRepositoryProvider));
});

/// Notifier for managing current user state
class CurrentUserNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final AuthRepository _authRepository;

  CurrentUserNotifier(this._authRepository) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final user = await _authRepository.getCurrentUser();
      state = AsyncValue.data(user);

      // Listen to auth state changes
      _authRepository.authStateChanges.listen((user) {
        state = AsyncValue.data(user);
      });
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
      final user = await _authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
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
      final user = await _authRepository.signIn(
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
