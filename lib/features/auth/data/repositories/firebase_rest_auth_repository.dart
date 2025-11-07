import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/user_entity.dart';

/// Firebase Authentication using REST API (no gRPC dependencies)
/// Works on iOS with Xcode 16+
class FirebaseRestAuthRepository {
  static const String _apiKey = 'AIzaSyAcbjRJIbMLDG5OEJytuBCaWBd8o0pMIWI';
  static const String _baseUrl = 'https://identitytoolkit.googleapis.com/v1/accounts';
  static const String _projectId = 'family-planner-86edd';
  static const String _firestoreBaseUrl = 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  String? _idToken;
  String? _userId;
  UserEntity? _currentUser;

  /// Sign in with email and password
  Future<UserEntity?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 [REST AUTH] Starting sign in for: $email');

      final url = Uri.parse('$_baseUrl:signInWithPassword?key=$_apiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _idToken = data['idToken'];
        _userId = data['localId'];

        print('🟢 [REST AUTH] Sign in successful, fetching user profile...');

        // Fetch user profile from Firestore
        var user = await _fetchUserProfile(_userId!);

        // If profile doesn't exist, create one with email only
        if (user == null) {
          print('⚠️  [REST AUTH] No profile found, creating one...');
          final newUser = UserEntity(
            id: _userId!,
            email: email,
            fullName: email.split('@')[0], // Use email username as default name
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _createUserProfile(newUser);
          user = await _fetchUserProfile(_userId!);
        }

        _currentUser = user;

        print('🟢 [REST AUTH] User: ${user?.fullName} (${user?.email})');
        return user;
      } else {
        final error = json.decode(response.body);
        print('🔴 [REST AUTH] Error: ${error['error']['message']}');
        throw Exception(error['error']['message']);
      }
    } catch (e) {
      print('🔴 [REST AUTH] Exception: $e');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<UserEntity?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      print('🔵 [REST AUTH] Starting sign up for: $email');

      final url = Uri.parse('$_baseUrl:signUp?key=$_apiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _idToken = data['idToken'];
        _userId = data['localId'];

        print('🟢 [REST AUTH] Sign up successful, creating user profile...');

        // Create user profile in Firestore
        final user = UserEntity(
          id: _userId!,
          email: email,
          fullName: fullName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _createUserProfile(user);
        _currentUser = user;

        print('🟢 [REST AUTH] User profile created: ${user.fullName}');
        return user;
      } else {
        final error = json.decode(response.body);
        print('🔴 [REST AUTH] Error: ${error['error']['message']}');
        throw Exception(error['error']['message']);
      }
    } catch (e) {
      print('🔴 [REST AUTH] Exception: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    print('🔵 [REST AUTH] Signing out...');
    _idToken = null;
    _userId = null;
    _currentUser = null;
    print('🟢 [REST AUTH] Signed out');
  }

  /// Get current user
  UserEntity? getCurrentUser() {
    return _currentUser;
  }

  /// Check if user is signed in
  bool isSignedIn() {
    return _idToken != null && _userId != null;
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return _userId;
  }

  /// Get ID token (for authenticated API calls)
  String? getIdToken() {
    return _idToken;
  }

  /// Fetch user profile from Firestore
  Future<UserEntity?> _fetchUserProfile(String userId) async {
    try {
      final url = Uri.parse('$_firestoreBaseUrl/users/$userId');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final fields = data['fields'];

        return UserEntity(
          id: userId,
          email: _getStringValue(fields['email']),
          fullName: _getStringValue(fields['fullName']),
          languagePreference: _getStringValue(fields['languagePreference']),
          createdAt: _getDateTimeValue(fields['createdAt']),
          updatedAt: _getDateTimeValue(fields['updatedAt']),
        );
      } else if (response.statusCode == 404) {
        // User profile doesn't exist in Firestore yet
        print('⚠️  [REST AUTH] User profile not found in Firestore');
        return null;
      } else {
        print('🔴 [REST AUTH] Failed to fetch user profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('🔴 [REST AUTH] Error fetching user profile: $e');
      return null;
    }
  }

  /// Create user profile in Firestore
  Future<void> _createUserProfile(UserEntity user) async {
    try {
      final url = Uri.parse('$_firestoreBaseUrl/users/${user.id}');

      final fields = <String, dynamic>{
        'email': {'stringValue': user.email},
        'fullName': {'stringValue': user.fullName ?? ''},
        'createdAt': {'timestampValue': user.createdAt.toUtc().toIso8601String()},
        'updatedAt': {'timestampValue': user.updatedAt.toUtc().toIso8601String()},
      };

      // Only add languagePreference if it's not null
      if (user.languagePreference != null) {
        fields['languagePreference'] = {'stringValue': user.languagePreference};
      }

      final requestBody = json.encode({'fields': fields});
      print('🔵 [REST AUTH] Creating profile with: $requestBody');

      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer $_idToken',
          'Content-Type': 'application/json',
        },
        body: requestBody,
      );

      if (response.statusCode == 200) {
        print('🟢 [REST AUTH] User profile created in Firestore');
      } else {
        print('🔴 [REST AUTH] Failed to create user profile: ${response.statusCode}');
        print('🔴 [REST AUTH] Response: ${response.body}');
      }
    } catch (e) {
      print('🔴 [REST AUTH] Error creating user profile: $e');
    }
  }

  // Helper methods to extract Firestore values
  String _getStringValue(dynamic field) {
    if (field == null) return '';
    return field['stringValue'] ?? '';
  }

  Map<String, dynamic> _getMapValue(dynamic field) {
    if (field == null) return {};
    final mapValue = field['mapValue'];
    if (mapValue == null) return {};
    // Simple map extraction - can be enhanced
    return {};
  }

  DateTime _getDateTimeValue(dynamic field) {
    if (field == null) return DateTime.now();
    final timestamp = field['timestampValue'];
    if (timestamp == null) return DateTime.now();
    return DateTime.parse(timestamp);
  }
}
