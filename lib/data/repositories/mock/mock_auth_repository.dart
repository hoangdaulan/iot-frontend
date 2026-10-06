import 'dart:typed_data';

import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/mock/mock_users.dart';
import 'package:gp1/data/models/dto/change_password_request.dart';
import 'package:gp1/data/models/dto/login_request.dart';
import 'package:gp1/data/models/dto/login_response.dart';
import 'package:gp1/data/models/dto/register_request.dart';
import 'package:gp1/data/models/dto/register_response.dart';
import 'package:gp1/data/models/dto/update_profile_request.dart';
import 'package:gp1/data/models/dto/user_summary.dart';
import 'package:gp1/data/models/user.dart';
import 'package:gp1/data/repositories/auth_repository.dart';

/// Accepts any credentials and always returns [mockUser].
class MockAuthRepository implements AuthRepository {
  static const _networkDelay = Duration(milliseconds: 300);

  @override
  Future<Result<LoginResponse>> login(LoginRequest request) async {
    await Future.delayed(_networkDelay);
    return Success(LoginResponse(accessToken: mockAccessToken, user: _summaryOf(mockUser)));
  }

  @override
  Future<Result<RegisterResponse>> register(RegisterRequest request) async {
    await Future.delayed(_networkDelay);
    return Success(
      RegisterResponse(
        message: 'Register successfully',
        user: UserSummary(
          id: mockUser.id + 1,
          username: request.username,
          name: request.name,
          role: UserRole.user,
        ),
      ),
    );
  }

  /// The signed-in mock user; profile edits last for the app session.
  var _user = mockUser;

  @override
  Future<Result<User>> getProfile() async => Success(_user);

  @override
  Future<Result<User>> updateProfile(UpdateProfileRequest request) async {
    await Future.delayed(_networkDelay);
    _user = _user.copyWith(
      name: request.name ?? _user.name,
      phone: request.phone ?? _user.phone,
      github: request.github ?? _user.github,
      figma: request.figma ?? _user.figma,
      swagger: request.swagger ?? _user.swagger,
    );
    return Success(_user);
  }

  @override
  Future<Result<User>> uploadAvatar({required Uint8List bytes, required String filename}) async {
    await Future.delayed(_networkDelay);
    return Success(_user);
  }

  @override
  Future<Result<void>> changePassword(ChangePasswordRequest request) async {
    await Future.delayed(_networkDelay);
    return const Success(null);
  }

  static UserSummary _summaryOf(User user) =>
      UserSummary(id: user.id, username: user.username, name: user.name, role: user.role);
}
