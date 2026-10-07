import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gp1/data/models/dto/user_info.dart';

part 'login_response.freezed.dart';
part 'login_response.g.dart';

/// Response of `POST /api/auth/login`.
@freezed
abstract class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    required String accessToken,

    /// Not part of the documented contract; kept for the existing refresh-token plumbing.
    String? refreshToken,
    required UserInfo user,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);
}
