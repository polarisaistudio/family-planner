import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

/// Firebase implementation of AuthRepository
class FirebaseAuthRepositoryImpl implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepositoryImpl(this._firebaseAuth, this._firestore);

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      print('🔵 [AUTH] Starting Firebase sign up for email: $email');
      print('🔵 [AUTH] Full name: $fullName');

      // Create user with Firebase Auth
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Sign up failed: No user returned');
      }

      print('🔵 [AUTH] User created with ID: ${credential.user!.uid}');

      // Update display name
      if (fullName != null) {
        await credential.user!.updateDisplayName(fullName);
      }

      // Create user document in Firestore
      final userData = {
        'id': credential.user!.uid,
        'email': email,
        'full_name': fullName,
        'language_preference': 'en',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userData);

      print('🟢 [AUTH] User profile created successfully');

      return UserEntity(
        id: credential.user!.uid,
        email: email,
        fullName: fullName,
        languagePreference: 'en',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('🔴 [AUTH] FirebaseAuthException: ${e.message}');
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      print('🔴 [AUTH] Generic error: $e');
      throw Exception('Sign up failed: $e');
    }
  }

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 [AUTH] Starting Firebase sign in for email: $email');
      print('🔵 [AUTH] Password length: ${password.length}');

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        print('🔴 [AUTH] No user returned from Firebase Auth');
        throw Exception('Sign in failed: No user returned');
      }

      print('🔵 [AUTH] User signed in with ID: ${credential.user!.uid}');
      print('🔵 [AUTH] Email verified: ${credential.user!.emailVerified}');

      // Fetch user profile from Firestore
      print('🔵 [AUTH] Fetching user profile from Firestore...');
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        print('🔴 [AUTH] User document not found in Firestore');
        throw Exception('User profile not found in database');
      }

      final data = userDoc.data()!;
      print('🟢 [AUTH] Sign in successful');
      print('🟢 [AUTH] User: ${data['full_name']} (${data['email']})');

      return UserEntity(
        id: credential.user!.uid,
        email: data['email'] as String,
        fullName: data['full_name'] as String?,
        languagePreference: data['language_preference'] as String? ?? 'en',
        createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('🔴 [AUTH] FirebaseAuthException Code: ${e.code}');
      print('🔴 [AUTH] FirebaseAuthException Message: ${e.message}');
      print('🔴 [AUTH] FirebaseAuthException Details: ${e.toString()}');
      throw Exception('Sign in failed: ${e.message} (Code: ${e.code})');
    } catch (e, stackTrace) {
      print('🔴 [AUTH] Generic error: $e');
      print('🔴 [AUTH] Error type: ${e.runtimeType}');
      print('🔴 [AUTH] Stack trace: $stackTrace');
      throw Exception('Sign in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return null;

      final data = userDoc.data()!;
      return UserEntity(
        id: user.uid,
        email: data['email'] as String,
        fullName: data['full_name'] as String?,
        languagePreference: data['language_preference'] as String? ?? 'en',
        createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
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
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      final updates = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (fullName != null) {
        updates['full_name'] = fullName;
        await user.updateDisplayName(fullName);
      }

      if (languagePreference != null) {
        updates['language_preference'] = languagePreference;
      }

      await _firestore.collection('users').doc(user.uid).update(updates);

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final data = userDoc.data()!;

      return UserEntity(
        id: user.uid,
        email: data['email'] as String,
        fullName: data['full_name'] as String?,
        languagePreference: data['language_preference'] as String? ?? 'en',
        createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      throw Exception('Update profile failed: $e');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _firebaseAuth.currentUser != null;
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception('Password reset failed: ${e.message}');
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final userDoc =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        if (!userDoc.exists) return null;

        final data = userDoc.data()!;
        return UserEntity(
          id: firebaseUser.uid,
          email: data['email'] as String,
          fullName: data['full_name'] as String?,
          languagePreference: data['language_preference'] as String? ?? 'en',
          createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      } catch (e) {
        return null;
      }
    });
  }
}
