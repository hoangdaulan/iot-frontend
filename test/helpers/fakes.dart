import 'dart:typed_data';

import 'package:gp1/core/base/local_data_base.dart';
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

class InMemoryLocalDataBase implements LocalDataBase {
  InMemoryLocalDataBase({this.accessToken, this.refreshToken});

  String? accessToken;
  String? refreshToken;

  @override
  Future<void> saveAccessToken(String token) async => accessToken = token;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<void> saveRefreshToken(String token) async => refreshToken = token;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
  }
}

/// Auth repository whose responses are set per test.
class FakeAuthRepository implements AuthRepository {
  Result<LoginResponse> loginResult = const Success(
    LoginResponse(
      accessToken: 'jwt-token',
      user: UserSummary(id: 1, username: 'admin', role: UserRole.admin),
    ),
  );
  Result<User> profileResult = const Success(mockUser);
  Result<RegisterResponse> registerResult = const Success(
    RegisterResponse(
      user: UserSummary(id: 2, username: 'user01', role: UserRole.user),
    ),
  );

  int profileCalls = 0;
  LoginRequest? lastLogin;
  RegisterRequest? lastRegister;

  @override
  Future<Result<LoginResponse>> login(LoginRequest request) async {
    lastLogin = request;
    return loginResult;
  }

  @override
  Future<Result<RegisterResponse>> register(RegisterRequest request) async {
    lastRegister = request;
    return registerResult;
  }

  @override
  Future<Result<User>> getProfile() async {
    profileCalls++;
    return profileResult;
  }

  @override
  Future<Result<User>> updateProfile(UpdateProfileRequest request) async => profileResult;

  Uint8List? lastAvatar;

  @override
  Future<Result<User>> uploadAvatar({required Uint8List bytes, required String filename}) async {
    lastAvatar = bytes;
    return profileResult;
  }

  @override
  Future<Result<void>> changePassword(ChangePasswordRequest request) async => const Success(null);
}
