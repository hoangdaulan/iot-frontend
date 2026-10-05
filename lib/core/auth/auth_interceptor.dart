import 'package:dio/dio.dart';
import 'package:gp1/app/config/app_config.dart';
import 'package:gp1/core/auth/auth_cubit_base.dart';
import 'package:gp1/core/base/local_data_base.dart';
import 'package:gp1/core/base/remote_data_base.dart';
import 'package:gp1/core/di/injection.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AuthInterceptor extends Interceptor {
  final Dio _retryDio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));

  static const String isRefreshTokenRequestKey = 'isRefreshTokenRequest';
  static const tokenExpired = 401;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = await getIt<LocalDataBase>().getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // A 401 on a request sent without a token (e.g. wrong login credentials) is not an
    // expired session.
    if (err.response == null ||
        err.response?.statusCode != tokenExpired ||
        err.requestOptions.extra[isRefreshTokenRequestKey] == true ||
        err.requestOptions.headers['Authorization'] == null) {
      return handler.next(err);
    }
    final localData = getIt<LocalDataBase>();
    final authCubit = getIt<AuthCubitBase>();
    final refreshToken = await localData.getRefreshToken();
    if (refreshToken == null) {
      // logout() also removes the rejected access token.
      authCubit.logout();
      return handler.reject(err);
    }

    try {
      final (newAccessToken, newRefreshToken) = await getIt<RemoteDataBase>().refreshToken(
        refreshToken,
      );
      await localData.saveTokens(newAccessToken, newRefreshToken);

      return await _retryRequest(err.requestOptions, handler, newAccessToken);
    } on DioException catch (e) {
      if (e.response?.statusCode == tokenExpired) {
        authCubit.logout();
      }
    }

    return handler.reject(err);
  }

  Future<void> _retryRequest(
    RequestOptions requestOptions,
    ErrorInterceptorHandler handler,
    String newAccessToken,
  ) async {
    try {
      requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      final response = await _retryDio.fetch(requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
