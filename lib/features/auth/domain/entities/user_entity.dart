import 'package:equatable/equatable.dart';

/// Domain entity representing a user
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String languagePreference;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.fullName,
    this.languagePreference = 'en',
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        languagePreference,
        createdAt,
        updatedAt,
      ];

  /// Create a copy with updated fields
  UserEntity copyWith({
    String? id,
    String? email,
    String? fullName,
    String? languagePreference,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      languagePreference: languagePreference ?? this.languagePreference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
