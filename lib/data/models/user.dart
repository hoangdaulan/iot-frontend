import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

enum UserRole {
  @JsonValue('ADMIN')
  admin('Admin'),
  @JsonValue('USER')
  user('User'),
  unknown('Unknown');

  final String label;

  const UserRole(this.label);
}

/// An authenticated account. Passwords never live here; they only travel in request DTOs
/// such as `LoginRequest` and `ChangePasswordRequest`.
@freezed
abstract class User with _$User {
  const factory User({
    required int id,
    required String username,
    required String email,
    @JsonKey(unknownEnumValue: UserRole.unknown) @Default(UserRole.unknown) UserRole role,
    String? name,
    String? phone,
    String? avatar,
    String? github,
    String? figma,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
