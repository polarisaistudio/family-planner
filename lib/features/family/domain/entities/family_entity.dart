import 'package:equatable/equatable.dart';

/// Domain entity representing a family group
class FamilyEntity extends Equatable {
  final String id;
  final String name;
  final String createdBy; // User ID of the creator
  final DateTime createdAt;
  final String? inviteCode; // Unique code for inviting members
  final DateTime? inviteCodeExpiresAt;

  const FamilyEntity({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    this.inviteCode,
    this.inviteCodeExpiresAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        createdBy,
        createdAt,
        inviteCode,
        inviteCodeExpiresAt,
      ];

  FamilyEntity copyWith({
    String? id,
    String? name,
    String? createdBy,
    DateTime? createdAt,
    String? inviteCode,
    DateTime? inviteCodeExpiresAt,
  }) {
    return FamilyEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      inviteCode: inviteCode ?? this.inviteCode,
      inviteCodeExpiresAt: inviteCodeExpiresAt ?? this.inviteCodeExpiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'inviteCode': inviteCode,
      'inviteCodeExpiresAt': inviteCodeExpiresAt?.toIso8601String(),
    };
  }

  factory FamilyEntity.fromJson(Map<String, dynamic> json) {
    return FamilyEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      inviteCode: json['inviteCode'] as String?,
      inviteCodeExpiresAt: json['inviteCodeExpiresAt'] != null
          ? DateTime.parse(json['inviteCodeExpiresAt'] as String)
          : null,
    );
  }
}
