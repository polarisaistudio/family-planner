import 'package:equatable/equatable.dart';

/// Represents a family member in the family planner
class FamilyMemberEntity extends Equatable {
  final String id;
  final String userId; // Firebase Auth UID - unique per user account
  final String familyId; // Links to family entity
  final String name;
  final String? email;
  final String? avatarUrl;
  final String? phoneNumber;
  final FamilyRole role;
  final String? color; // Hex color for calendar display
  final DateTime joinedAt;
  final bool isActive;
  final String? deviceToken; // FCM token for push notifications
  final Map<String, dynamic>? preferences;

  const FamilyMemberEntity({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.name,
    this.email,
    this.avatarUrl,
    this.phoneNumber,
    this.role = FamilyRole.member,
    this.color,
    required this.joinedAt,
    this.isActive = true,
    this.deviceToken,
    this.preferences,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        familyId,
        name,
        email,
        avatarUrl,
        phoneNumber,
        role,
        color,
        joinedAt,
        isActive,
        deviceToken,
        preferences,
      ];

  FamilyMemberEntity copyWith({
    String? id,
    String? userId,
    String? familyId,
    String? name,
    String? email,
    String? avatarUrl,
    String? phoneNumber,
    FamilyRole? role,
    String? color,
    DateTime? joinedAt,
    bool? isActive,
    String? deviceToken,
    Map<String, dynamic>? preferences,
  }) {
    return FamilyMemberEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      color: color ?? this.color,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
      deviceToken: deviceToken ?? this.deviceToken,
      preferences: preferences ?? this.preferences,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'familyId': familyId,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'phoneNumber': phoneNumber,
      'role': role.name,
      'color': color,
      'joinedAt': joinedAt.toIso8601String(),
      'isActive': isActive,
      'deviceToken': deviceToken,
      'preferences': preferences,
    };
  }

  factory FamilyMemberEntity.fromJson(Map<String, dynamic> json) {
    return FamilyMemberEntity(
      id: json['id'] as String,
      userId: json['userId'] as String,
      familyId: json['familyId'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      role: FamilyRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => FamilyRole.member,
      ),
      color: json['color'] as String?,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      deviceToken: json['deviceToken'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }
}

enum FamilyRole {
  admin,  // Can add/remove members, manage family settings
  member, // Regular family member
  child,  // Limited permissions (optional)
}

/// Represents a task comment
class TaskCommentEntity extends Equatable {
  final String id;
  final String taskId;
  final String authorId; // FamilyMember id
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isEdited;

  const TaskCommentEntity({
    required this.id,
    required this.taskId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.isEdited = false,
  });

  @override
  List<Object?> get props => [
        id,
        taskId,
        authorId,
        authorName,
        authorAvatarUrl,
        content,
        createdAt,
        updatedAt,
        isEdited,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatarUrl': authorAvatarUrl,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isEdited': isEdited,
    };
  }

  factory TaskCommentEntity.fromJson(Map<String, dynamic> json) {
    return TaskCommentEntity(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorAvatarUrl: json['authorAvatarUrl'] as String?,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      isEdited: json['isEdited'] as bool? ?? false,
    );
  }
}
