import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gp1/data/models/user.dart';

part 'user_summary.freezed.dart';
part 'user_summary.g.dart';

/// The partial user embedded in the login and register responses. The full profile (with
/// email etc.) comes from `GET /api/auth/profile` as a `User`.
@freezed
abstract class UserSummary with _$UserSummary {
  const factory UserSummary({
    required int id,
    required String username,
    String? name,
    @JsonKey(unknownEnumValue: UserRole.unknown) @Default(UserRole.unknown) UserRole role,
  }) = _UserSummary;

  factory UserSummary.fromJson(Map<String, dynamic> json) => _$UserSummaryFromJson(json);
}
