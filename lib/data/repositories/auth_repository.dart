import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/change_password_request.dart';
import 'package:gp1/data/models/dto/login_request.dart';
import 'package:gp1/data/models/dto/login_response.dart';
import 'package:gp1/data/models/dto/register_request.dart';
import 'package:gp1/data/models/dto/register_response.dart';
import 'package:gp1/data/models/dto/update_profile_request.dart';
import 'package:gp1/data/models/user.dart';

/// HTTP failures are reported as `Failure(code: <HTTP status>)`, so callers can tell an
/// authentication failure (401) from a network/server failure.
abstract interface class AuthRepository {
  /// `POST /api/auth/login`
  Future<Result<LoginResponse>> login(LoginRequest request);

  /// `POST /api/auth/register`
  Future<Result<RegisterResponse>> register(RegisterRequest request);

  /// `GET /api/auth/profile`
  Future<Result<User>> getProfile();

  /// `PATCH /api/auth/profile`
  Future<Result<User>> updateProfile(UpdateProfileRequest request);

  /// `PATCH /api/auth/password`
  Future<Result<void>> changePassword(ChangePasswordRequest request);
}
