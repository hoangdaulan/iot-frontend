import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gp1/data/models/dto/user_info.dart';

part 'register_response.freezed.dart';
part 'register_response.g.dart';

/// Response of `POST /api/auth/register` (201 Created).
@freezed
abstract class RegisterResponse with _$RegisterResponse {
  const factory RegisterResponse({String? message, required UserInfo user}) = _RegisterResponse;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) => _$RegisterResponseFromJson(json);
}
