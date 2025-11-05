import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../domain/entities/family_entity.dart';
import '../../domain/entities/family_member_entity.dart';
import '../../utils/invite_code_generator.dart';

/// Repository for managing family creation, invites, and joining
class FamilyManagementRepository {
  static const String _projectId = 'family-planner-86edd';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  final String Function() _getIdToken;
  final String Function() _getUserId;

  FamilyManagementRepository({
    required String Function() getIdToken,
    required String Function() getUserId,
  })  : _getIdToken = getIdToken,
        _getUserId = getUserId;

  /// Create a new family with the current user as admin
  Future<FamilyEntity> createFamily(
    String familyName,
    String userName, {
    String? deviceToken,
  }) async {
    try {
      final userId = _getUserId();
      final familyId = const Uuid().v4();
      final inviteCode = InviteCodeGenerator.generateCode();

      print('🔵 [FAMILY MGMT] Creating family: $familyName');

      final family = FamilyEntity(
        id: familyId,
        name: familyName,
        createdBy: userId,
        createdAt: DateTime.now(),
        inviteCode: inviteCode,
        inviteCodeExpiresAt: InviteCodeGenerator.generateExpirationDate(),
      );

      // Create family document
      final familyUrl = '$_baseUrl/families/${family.id}';
      final familyResponse = await http.patch(
        Uri.parse(familyUrl),
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'fields': _familyToFirestore(family),
        }),
      );

      if (familyResponse.statusCode != 200) {
        throw Exception('Failed to create family: ${familyResponse.statusCode}');
      }

      // Create admin member entry
      final member = FamilyMemberEntity(
        id: const Uuid().v4(),
        userId: userId,
        familyId: familyId,
        name: userName,
        role: FamilyRole.admin,
        joinedAt: DateTime.now(),
        color: '#FF5252', // Default red color
        deviceToken: deviceToken,
      );

      final memberUrl = '$_baseUrl/family_members/${member.id}';
      final memberResponse = await http.patch(
        Uri.parse(memberUrl),
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'fields': _familyMemberToFirestore(member),
        }),
      );

      if (memberResponse.statusCode != 200) {
        throw Exception('Failed to create member: ${memberResponse.statusCode}');
      }

      print('🟢 [FAMILY MGMT] Family created with invite code: $inviteCode');
      return family;
    } catch (e) {
      print('🔴 [FAMILY MGMT] Error creating family: $e');
      rethrow;
    }
  }

  /// Get family by invite code
  Future<FamilyEntity?> getFamilyByInviteCode(String inviteCode) async {
    try {
      final normalizedCode = InviteCodeGenerator.normalizeCode(inviteCode);
      print('🔵 [FAMILY MGMT] Looking up family with code: $normalizedCode');

      final url = '$_baseUrl/families';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final documents = data['documents'] as List<dynamic>? ?? [];

        for (var doc in documents) {
          final fields = doc['fields'] as Map<String, dynamic>;
          final docInviteCode = _getStringValue(fields['inviteCode']);

          if (docInviteCode != null &&
              InviteCodeGenerator.normalizeCode(docInviteCode) == normalizedCode) {
            final family = _familyFromFirestore(doc);

            // Check if expired
            if (InviteCodeGenerator.isExpired(family.inviteCodeExpiresAt)) {
              print('🔴 [FAMILY MGMT] Invite code expired');
              return null;
            }

            print('🟢 [FAMILY MGMT] Found family: ${family.name}');
            return family;
          }
        }
      }

      print('🔴 [FAMILY MGMT] No family found with that code');
      return null;
    } catch (e) {
      print('🔴 [FAMILY MGMT] Error looking up family: $e');
      return null;
    }
  }

  /// Join a family using invite code
  Future<FamilyMemberEntity> joinFamily(
    String inviteCode,
    String userName,
    String? email, {
    String? deviceToken,
  }) async {
    try {
      final userId = _getUserId();
      print('🔵 [FAMILY MGMT] Joining family with code: $inviteCode');

      // Find family by invite code
      final family = await getFamilyByInviteCode(inviteCode);
      if (family == null) {
        throw Exception('Invalid or expired invite code');
      }

      // Check if user is already a member
      final existingMember = await _checkIfUserInFamily(userId, family.id);
      if (existingMember != null) {
        print('🟡 [FAMILY MGMT] User already in family');
        return existingMember;
      }

      // Create new member
      final member = FamilyMemberEntity(
        id: const Uuid().v4(),
        userId: userId,
        familyId: family.id,
        name: userName,
        email: email,
        role: FamilyRole.member,
        joinedAt: DateTime.now(),
        color: '#448AFF', // Default blue color
        deviceToken: deviceToken,
      );

      final memberUrl = '$_baseUrl/family_members/${member.id}';
      final response = await http.patch(
        Uri.parse(memberUrl),
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'fields': _familyMemberToFirestore(member),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to join family: ${response.statusCode}');
      }

      print('🟢 [FAMILY MGMT] Successfully joined family: ${family.name}');
      return member;
    } catch (e) {
      print('🔴 [FAMILY MGMT] Error joining family: $e');
      rethrow;
    }
  }

  /// Check if user is already in a family
  Future<FamilyMemberEntity?> _checkIfUserInFamily(String userId, String familyId) async {
    try {
      final url = '$_baseUrl/family_members';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final documents = data['documents'] as List<dynamic>? ?? [];

        for (var doc in documents) {
          final fields = doc['fields'] as Map<String, dynamic>;
          final docUserId = _getStringValue(fields['userId']);
          final docFamilyId = _getStringValue(fields['familyId']);

          if (docUserId == userId && docFamilyId == familyId) {
            return _familyMemberFromFirestore(doc);
          }
        }
      }
      return null;
    } catch (e) {
      print('🔴 [FAMILY MGMT] Error checking membership: $e');
      return null;
    }
  }

  /// Regenerate invite code for a family
  Future<FamilyEntity> regenerateInviteCode(String familyId) async {
    try {
      print('🔵 [FAMILY MGMT] Regenerating invite code for family: $familyId');

      // Get current family
      final familyUrl = '$_baseUrl/families/$familyId';
      final getResponse = await http.get(
        Uri.parse(familyUrl),
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (getResponse.statusCode != 200) {
        throw Exception('Family not found');
      }

      final doc = json.decode(getResponse.body);
      final family = _familyFromFirestore(doc);

      // Generate new code
      final newCode = InviteCodeGenerator.generateCode();
      final updatedFamily = family.copyWith(
        inviteCode: newCode,
        inviteCodeExpiresAt: InviteCodeGenerator.generateExpirationDate(),
      );

      // Update family
      final updateResponse = await http.patch(
        Uri.parse(familyUrl),
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'fields': _familyToFirestore(updatedFamily),
        }),
      );

      if (updateResponse.statusCode != 200) {
        throw Exception('Failed to update invite code');
      }

      print('🟢 [FAMILY MGMT] New invite code: $newCode');
      return updatedFamily;
    } catch (e) {
      print('🔴 [FAMILY MGMT] Error regenerating code: $e');
      rethrow;
    }
  }

  // Firestore conversion helpers
  Map<String, dynamic> _familyToFirestore(FamilyEntity family) {
    return {
      'id': {'stringValue': family.id},
      'name': {'stringValue': family.name},
      'createdBy': {'stringValue': family.createdBy},
      'createdAt': {'timestampValue': family.createdAt.toUtc().toIso8601String()},
      'inviteCode': family.inviteCode != null
          ? {'stringValue': family.inviteCode}
          : {'nullValue': null},
      'inviteCodeExpiresAt': family.inviteCodeExpiresAt != null
          ? {'timestampValue': family.inviteCodeExpiresAt!.toUtc().toIso8601String()}
          : {'nullValue': null},
    };
  }

  FamilyEntity _familyFromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>;
    return FamilyEntity(
      id: _getStringValue(fields['id']) ?? '',
      name: _getStringValue(fields['name']) ?? '',
      createdBy: _getStringValue(fields['createdBy']) ?? '',
      createdAt: DateTime.parse(
        _getStringValue(fields['createdAt']) ?? DateTime.now().toIso8601String(),
      ),
      inviteCode: _getStringValue(fields['inviteCode']),
      inviteCodeExpiresAt: fields['inviteCodeExpiresAt']?['timestampValue'] != null
          ? DateTime.parse(fields['inviteCodeExpiresAt']['timestampValue'] as String)
          : null,
    );
  }

  Map<String, dynamic> _familyMemberToFirestore(FamilyMemberEntity member) {
    return {
      'id': {'stringValue': member.id},
      'userId': {'stringValue': member.userId},
      'familyId': {'stringValue': member.familyId},
      'name': {'stringValue': member.name},
      'email': member.email != null ? {'stringValue': member.email} : {'nullValue': null},
      'role': {'stringValue': member.role.name},
      'color': member.color != null ? {'stringValue': member.color} : {'nullValue': null},
      'joinedAt': {'timestampValue': member.joinedAt.toUtc().toIso8601String()},
      'isActive': {'booleanValue': member.isActive},
    };
  }

  FamilyMemberEntity _familyMemberFromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>;
    return FamilyMemberEntity(
      id: _getStringValue(fields['id']) ?? '',
      userId: _getStringValue(fields['userId']) ?? '',
      familyId: _getStringValue(fields['familyId']) ?? '',
      name: _getStringValue(fields['name']) ?? '',
      email: _getStringValue(fields['email']),
      role: FamilyRole.values.firstWhere(
        (e) => e.name == _getStringValue(fields['role']),
        orElse: () => FamilyRole.member,
      ),
      color: _getStringValue(fields['color']),
      joinedAt: DateTime.parse(
        _getStringValue(fields['joinedAt']) ?? DateTime.now().toIso8601String(),
      ),
      isActive: fields['isActive']?['booleanValue'] as bool? ?? true,
    );
  }

  String? _getStringValue(Map<String, dynamic>? field) {
    if (field == null) return null;
    if (field['stringValue'] != null) return field['stringValue'] as String;
    if (field['timestampValue'] != null) return field['timestampValue'] as String;
    return null;
  }
}
