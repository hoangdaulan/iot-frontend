import 'package:json_annotation/json_annotation.dart';

part 'register_request.g.dart';

/// Body of `POST /api/auth/register`.
@JsonSerializable(createFactory: false, includeIfNull: false)
class RegisterRequest {
  const RegisterRequest({
    required this.username,
    required this.email,
    required this.password,
    this.name,
  });

  /// Full name.
  final String? name;
  final String username;
  final String email;
  final String password;

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}
