import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gp1/app/config/app_config.dart';
import 'package:gp1/core/auth/auth_interceptor.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Dio client for the MyIoT backend: JSON, Bearer token (via [AuthInterceptor]) and, in debug
/// builds, request logging into the Talker screen.
Dio createApiClient({required Talker talker}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      connectTimeout: const Duration(seconds: 10),
      // Device commands wait for the ESP32 (backend timeout 5 s) before answering.
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
  dio.interceptors.add(AuthInterceptor());
  if (kDebugMode) {
    dio.interceptors.add(
      TalkerDioLogger(
        talker: talker,
        settings: const TalkerDioLoggerSettings(printRequestHeaders: false),
      ),
    );
  }
  return dio;
}
