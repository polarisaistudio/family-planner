import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/family_member_entity.dart';

/// Repository for family member and collaboration operations
/// Uses Firebase REST API for iOS compatibility
class FamilyRepository {
  static const String _projectId = 'family-planner-86edd';
  static const String _baseUrl =
      'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

  final String Function() _getIdToken;
  final String Function() _getUserId;

  FamilyRepository({
    required String Function() getIdToken,
    required String Function() getUserId,
  })  : _getIdToken = getIdToken,
        _getUserId = getUserId;

  /// Get all family members for a family
  Future<List<FamilyMemberEntity>> getFamilyMembers(String familyId) async {
    try {
      print('🔵 [FAMILY REPO] Fetching family members for family: $familyId');

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

        final members = documents
            .map((doc) {
              final fields = doc['fields'] as Map<String, dynamic>;
              final memberFamilyId = _getStringValue(fields['familyId']);

              // Filter by familyId
              if (memberFamilyId == familyId) {
                return _familyMemberFromFirestore(doc);
              }
              return null;
            })
            .whereType<FamilyMemberEntity>()
            .toList();

        print('🟢 [FAMILY REPO] Found ${members.length} family members');
        return members;
      } else {
        print('🔴 [FAMILY REPO] Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('🔴 [FAMILY REPO] Error fetching family members: $e');
      return [];
    }
  }

  /// Get a specific family member
  Future<FamilyMemberEntity?> getFamilyMember(String memberId) async {
    try {
      final url = '$_baseUrl/family_members/$memberId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final doc = json.decode(response.body);
        return _familyMemberFromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('🔴 [FAMILY REPO] Error fetching member: $e');
      return null;
    }
  }

  /// Create a new family member
  Future<void> createFamilyMember(FamilyMemberEntity member) async {
    try {
      print('🔵 [FAMILY REPO] Creating family member: ${member.name}');

      final url = '$_baseUrl/family_members/${member.id}';
      final body = json.encode({
        'fields': _familyMemberToFirestore(member),
      });

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        print('🟢 [FAMILY REPO] Family member created successfully');
      } else {
        print('🔴 [FAMILY REPO] Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🔴 [FAMILY REPO] Error creating family member: $e');
      rethrow;
    }
  }

  /// Update a family member
  Future<void> updateFamilyMember(FamilyMemberEntity member) async {
    try {
      final url = '$_baseUrl/family_members/${member.id}';
      final body = json.encode({
        'fields': _familyMemberToFirestore(member),
      });

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        print('🟢 [FAMILY REPO] Family member updated successfully');
      } else {
        print('🔴 [FAMILY REPO] Error: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [FAMILY REPO] Error updating family member: $e');
      rethrow;
    }
  }

  /// Delete a family member
  Future<void> deleteFamilyMember(String memberId) async {
    try {
      final url = '$_baseUrl/family_members/$memberId';
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('🟢 [FAMILY REPO] Family member deleted successfully');
      } else {
        print('🔴 [FAMILY REPO] Error: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [FAMILY REPO] Error deleting family member: $e');
      rethrow;
    }
  }

  /// Get comments for a task
  Future<List<TaskCommentEntity>> getTaskComments(String taskId) async {
    try {
      final url = '$_baseUrl/task_comments';
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

        final comments = documents
            .map((doc) {
              final fields = doc['fields'] as Map<String, dynamic>;
              final commentTaskId = _getStringValue(fields['taskId']);

              if (commentTaskId == taskId) {
                return _taskCommentFromFirestore(doc);
              }
              return null;
            })
            .whereType<TaskCommentEntity>()
            .toList();

        // Sort by creation date (newest first)
        comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return comments;
      }
      return [];
    } catch (e) {
      print('🔴 [FAMILY REPO] Error fetching comments: $e');
      return [];
    }
  }

  /// Add a comment to a task
  Future<void> addTaskComment(TaskCommentEntity comment) async {
    try {
      final url = '$_baseUrl/task_comments/${comment.id}';
      final body = json.encode({
        'fields': _taskCommentToFirestore(comment),
      });

      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        print('🟢 [FAMILY REPO] Comment added successfully');
      } else {
        print('🔴 [FAMILY REPO] Error: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 [FAMILY REPO] Error adding comment: $e');
      rethrow;
    }
  }

  /// Delete a comment
  Future<void> deleteTaskComment(String commentId) async {
    try {
      final url = '$_baseUrl/task_comments/$commentId';
      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer ${_getIdToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('🟢 [FAMILY REPO] Comment deleted successfully');
      }
    } catch (e) {
      print('🔴 [FAMILY REPO] Error deleting comment: $e');
      rethrow;
    }
  }

  // Helper methods for Firestore conversion

  Map<String, dynamic> _familyMemberToFirestore(FamilyMemberEntity member) {
    return {
      'id': {'stringValue': member.id},
      'userId': {'stringValue': member.userId},
      'familyId': {'stringValue': member.familyId},
      'name': {'stringValue': member.name},
      'email': member.email != null ? {'stringValue': member.email} : {'nullValue': null},
      'avatarUrl': member.avatarUrl != null ? {'stringValue': member.avatarUrl} : {'nullValue': null},
      'phoneNumber': member.phoneNumber != null ? {'stringValue': member.phoneNumber} : {'nullValue': null},
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
      avatarUrl: _getStringValue(fields['avatarUrl']),
      phoneNumber: _getStringValue(fields['phoneNumber']),
      role: FamilyRole.values.firstWhere(
        (e) => e.name == _getStringValue(fields['role']),
        orElse: () => FamilyRole.member,
      ),
      color: _getStringValue(fields['color']),
      joinedAt: DateTime.parse(_getStringValue(fields['joinedAt']) ?? DateTime.now().toIso8601String()),
      isActive: fields['isActive']?['booleanValue'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _taskCommentToFirestore(TaskCommentEntity comment) {
    return {
      'id': {'stringValue': comment.id},
      'taskId': {'stringValue': comment.taskId},
      'authorId': {'stringValue': comment.authorId},
      'authorName': {'stringValue': comment.authorName},
      'authorAvatarUrl': comment.authorAvatarUrl != null
          ? {'stringValue': comment.authorAvatarUrl}
          : {'nullValue': null},
      'content': {'stringValue': comment.content},
      'createdAt': {'timestampValue': comment.createdAt.toUtc().toIso8601String()},
      'updatedAt': comment.updatedAt != null
          ? {'timestampValue': comment.updatedAt!.toUtc().toIso8601String()}
          : {'nullValue': null},
      'isEdited': {'booleanValue': comment.isEdited},
    };
  }

  TaskCommentEntity _taskCommentFromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>;

    return TaskCommentEntity(
      id: _getStringValue(fields['id']) ?? '',
      taskId: _getStringValue(fields['taskId']) ?? '',
      authorId: _getStringValue(fields['authorId']) ?? '',
      authorName: _getStringValue(fields['authorName']) ?? '',
      authorAvatarUrl: _getStringValue(fields['authorAvatarUrl']),
      content: _getStringValue(fields['content']) ?? '',
      createdAt: DateTime.parse(_getStringValue(fields['createdAt']) ?? DateTime.now().toIso8601String()),
      updatedAt: fields['updatedAt']?['timestampValue'] != null
          ? DateTime.parse(fields['updatedAt']['timestampValue'] as String)
          : null,
      isEdited: fields['isEdited']?['booleanValue'] as bool? ?? false,
    );
  }

  String? _getStringValue(Map<String, dynamic>? field) {
    if (field == null) return null;
    return field['stringValue'] as String?;
  }
}
