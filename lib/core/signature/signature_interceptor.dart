import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:gp1/app/config/app_config.dart';

class SignatureInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final secret = AppConfig.signatureSecret;
    if (secret.isNotEmpty) {
      final timestamp = _currentTimestamp();
      final payload = '$timestamp\n${options.method}\n${options.uri.path}';
      final mac = Hmac(sha256, utf8.encode(secret));
      final signature = mac.convert(utf8.encode(payload)).toString();
      options.headers['X-App-Token'] = signature;
    }
    handler.next(options);
  }

  String _currentTimestamp() {
    final now = DateTime.now();
    final truncated = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    return truncated.millisecondsSinceEpoch.toString();
  }
}
