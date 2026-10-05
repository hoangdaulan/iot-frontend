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
        user: UserSummary(id: mockUser.id + 1, username: request.username, role: UserRole.user),
      ),
    );
  }

  @override
  Future<Result<User>> getProfile() async => const Success(mockUser);

  @override
  Future<Result<User>> updateProfile(UpdateProfileRequest request) async {
    await Future.delayed(_networkDelay);
    return Success(
      mockUser.copyWith(
        phone: request.phone ?? mockUser.phone,
        github: request.github ?? mockUser.github,
        figma: request.figma ?? mockUser.figma,
      ),
    );
  }

  @override
  Future<Result<void>> changePassword(ChangePasswordRequest request) async {
    await Future.delayed(_networkDelay);
    return const Success(null);
  }

  static UserSummary _summaryOf(User user) =>
      UserSummary(id: user.id, username: user.username, name: user.name, role: user.role);
}
