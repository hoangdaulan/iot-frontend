import 'package:dio/dio.dart';
import 'package:gp1/core/base/result.dart';

/// Runs [request] and maps any Dio error to a [Failure] whose `code` is the HTTP status (null
/// when the server could not be reached) and whose `message` is the backend's `message`.
Future<Result<T>> guardRequest<T>(Future<T> Function() request) async {
  try {
    return Success(await request());
  } on DioException catch (e) {
    return failureFromDio(e);
  }
}

Failure<T> failureFromDio<T>(DioException e) {
  final response = e.response;
  if (response == null) {
    return Failure(
      message: switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => 'The server took too long to respond.',
        DioExceptionType.cancel => 'The request was cancelled.',
        _ => 'Cannot reach the server. Check your connection.',
      },
    );
  }

  final status = response.statusCode;
  final data = response.data;
  final serverMessage = data is Map && data['message'] is String ? data['message'] as String : null;
  return Failure(code: status, message: serverMessage ?? _defaultMessage(status));
}

String _defaultMessage(int? status) => switch (status) {
  400 => 'Invalid request data',
  401 => 'Unauthorized',
  403 => 'You do not have permission',
  404 => 'Not found',
  409 => 'Already exists',
  500 => 'Internal server error',
  504 => 'The device did not respond in time',
  _ => 'Unexpected server error ($status)',
};
