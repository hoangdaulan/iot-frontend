import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gp1/data/models/user.dart';

part 'user_info.freezed.dart';
part 'user_info.g.dart';

/// The partial user embedded in the login and register responses. The full profile (with
/// email etc.) comes from `GET /api/auth/profile` as a `User`.
@freezed
abstract class UserInfo with _$UserInfo {
  const UserInfo._();

  const factory UserInfo({
    required int id,
    required String username,
    String? name,
    @JsonKey(unknownEnumValue: UserRole.unknown) @Default(UserRole.unknown) UserRole role,
  }) = _UserInfo;

  factory UserInfo.fromJson(Map<String, dynamic> json) => _$UserInfoFromJson(json);

  /// The full name, or the username when none was given.
  String get displayName => (name ?? '').trim().isEmpty ? username : name!.trim();
}
