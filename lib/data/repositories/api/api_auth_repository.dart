import 'package:dio/dio.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/change_password_request.dart';
import 'package:gp1/data/models/dto/login_request.dart';
import 'package:gp1/data/models/dto/login_response.dart';
import 'package:gp1/data/models/dto/register_request.dart';
import 'package:gp1/data/models/dto/register_response.dart';
import 'package:gp1/data/models/dto/update_profile_request.dart';
import 'package:gp1/data/models/user.dart';
import 'package:gp1/data/remote/api_failure.dart';
import 'package:gp1/data/repositories/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._dio);

  final Dio _dio;

  @override
  Future<Result<LoginResponse>> login(LoginRequest request) => guardRequest(() async {
    final res = await _dio.post<Map<String, dynamic>>('/api/auth/login', data: request.toJson());
    return LoginResponse.fromJson(res.data!);
  });

  @override
  Future<Result<RegisterResponse>> register(RegisterRequest request) => guardRequest(() async {
    final res = await _dio.post<Map<String, dynamic>>('/api/auth/register', data: request.toJson());
    return RegisterResponse.fromJson(res.data!);
  });

  @override
  Future<Result<User>> getProfile() => guardRequest(() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/auth/profile');
    return User.fromJson(res.data!);
  });

  @override
  Future<Result<User>> updateProfile(UpdateProfileRequest request) => guardRequest(() async {
    final res = await _dio.patch<Map<String, dynamic>>('/api/auth/profile', data: request.toJson());
    return User.fromJson(res.data!);
  });

  @override
  Future<Result<void>> changePassword(ChangePasswordRequest request) => guardRequest(() async {
    await _dio.patch<void>('/api/auth/password', data: request.toJson());
  });
}
