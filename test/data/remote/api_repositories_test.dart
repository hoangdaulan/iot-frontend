import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/dto/device_history_query.dart';
import 'package:gp1/data/models/dto/login_request.dart';
import 'package:gp1/data/models/dto/sensor_history_query.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/user.dart';
import 'package:gp1/data/repositories/api/api_auth_repository.dart';
import 'package:gp1/data/repositories/api/api_device_repository.dart';
import 'package:gp1/data/repositories/api/api_sensor_repository.dart';

/// Answers every request with a fixed status and JSON body, and records the request.
class _FakeBackend implements HttpClientAdapter {
  _FakeBackend(this.status, [this.body]);

  final int status;
  final Object? body;
  RequestOptions? request;
  Object? requestBody;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    requestBody = options.data;
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _UnreachableBackend implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? _, Future<void>? _) =>
      throw DioException.connectionError(requestOptions: options, reason: 'refused');

  @override
  void close({bool force = false}) {}
}

Dio _dio(HttpClientAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'http://api.test'))..httpClientAdapter = adapter;

void main() {
  group('ApiAuthRepository', () {
    test('login posts the credentials and parses the user summary', () async {
      final backend = _FakeBackend(200, {
        'accessToken': 'jwt',
        'user': {'id': 1, 'username': 'admin', 'name': 'Administrator', 'role': 'ADMIN'},
      });

      final result = await ApiAuthRepository(
        _dio(backend),
      ).login(const LoginRequest(username: 'admin', password: '123456'));

      expect(backend.request?.method, 'POST');
      expect(backend.request?.path, '/api/auth/login');
      expect(backend.requestBody, {'username': 'admin', 'password': '123456'});
      expect(result.dataOrNull?.accessToken, 'jwt');
      expect(result.dataOrNull?.user.role, UserRole.admin);
    });

    test('getProfile parses the full user', () async {
      final result = await ApiAuthRepository(
        _dio(
          _FakeBackend(200, {
            'id': 1,
            'email': 'admin@myiot.local',
            'username': 'admin',
            'role': 'ADMIN',
          }),
        ),
      ).getProfile();

      expect(result.dataOrNull?.email, 'admin@myiot.local');
    });
  });

  group('ApiSensorRepository', () {
    test('history sends the query and parses the grouped page', () async {
      final backend = _FakeBackend(200, {
        'data': {
          'temperature': [
            {'id': 1, 'value': 26.5, 'unit': '°C', 'timestamp': '2026-08-14T14:00:05Z'},
          ],
          'humidity': <Object>[],
          'light': <Object>[],
        },
        'page': 0,
        'pageSize': 20,
        'totalElements': 1,
        'totalPages': 1,
      });

      final result = await ApiSensorRepository(
        _dio(backend),
      ).getSensorHistory(const SensorHistoryQuery(type: SensorType.temperature, size: 20));

      expect(backend.request?.path, '/api/sensor-data/history');
      expect(backend.request?.queryParameters, {'type': 'temperature', 'size': '20'});
      expect(result.dataOrNull?.toReadings().single.value, 26.5);
    });

    test('latest has no device parameter and reads the LED status', () async {
      final backend = _FakeBackend(200, {
        'data': {
          'light': {'id': 9, 'value': 420, 'unit': 'lux', 'timestamp': '2026-08-14T14:00:05Z'},
        },
        'deviceStatus': 'ON',
      });

      final result = await ApiSensorRepository(_dio(backend)).getLatestSensorData();

      expect(backend.request?.path, '/api/sensor-data/latest');
      expect(backend.request?.queryParameters, isEmpty);
      expect(result.dataOrNull?.deviceStatus, DeviceStatus.on);
    });
  });

  group('ApiDeviceRepository', () {
    test('getDevices parses the device list', () async {
      final backend = _FakeBackend(200, [
        {'id': 1, 'name': 'LED 1', 'type': 'LED', 'status': 'ON'},
        {'id': 2, 'name': 'LED 2', 'type': 'LED', 'status': 'OFF'},
      ]);

      final result = await ApiDeviceRepository(_dio(backend)).getDevices();

      expect(backend.request?.path, '/api/devices');
      expect(result.dataOrNull?.map((d) => d.name), ['LED 1', 'LED 2']);
      expect(result.dataOrNull?.first.isOn, isTrue);
    });

    test('sendCommand posts to the given device', () async {
      final backend = _FakeBackend(200, {
        'deviceId': 1,
        'command': 'ON',
        'status': 'SUCCESS',
        'message': 'Device turned on successfully',
      });

      final result = await ApiDeviceRepository(_dio(backend)).sendCommand(1, DeviceCommand.on);

      expect(backend.request?.path, '/api/devices/1/command');
      expect(backend.requestBody, {'command': 'ON'});
      expect(result.dataOrNull?.isSuccess, isTrue);
    });

    test('a 504 hardware timeout with a result body is a TIMEOUT result, not a failure', () async {
      final result = await ApiDeviceRepository(
        _dio(
          _FakeBackend(504, {
            'deviceId': 1,
            'command': 'OFF',
            'status': 'TIMEOUT',
            'message': 'Device did not respond in time',
          }),
        ),
      ).sendCommand(1, DeviceCommand.off);

      expect(result, isA<Success>());
      expect(result.dataOrNull?.status, DeviceActionResult.timeout);
      expect(result.dataOrNull?.message, 'Device did not respond in time');
    });

    test('control history parses the page response', () async {
      final backend = _FakeBackend(200, {
        'content': [
          {
            'id': 101,
            'deviceId': 1,
            'deviceName': 'ESP32',
            'action': 'TURN_ON',
            'status': 'ON',
            'result': 'SUCCESS',
            'timestamp': '2026-08-19T14:30:05Z',
          },
        ],
        'page': 0,
        'size': 20,
        'totalElements': 1,
        'totalPages': 1,
      });

      final result = await ApiDeviceRepository(
        _dio(backend),
      ).getControlHistory(const DeviceHistoryQuery(size: 20));

      expect(backend.request?.queryParameters, {'size': '20'});
      expect(result.dataOrNull?.content.single.deviceName, 'ESP32');
    });
  });

  group('HTTP error mapping', () {
    for (final (status, message) in [
      (400, 'Invalid request data'),
      (401, 'Unauthorized'),
      (403, 'You do not have permission'),
      (404, 'Device not found'),
      (409, 'Username or email already exists'),
      (500, 'Internal server error'),
      (504, 'Gateway timeout'),
    ]) {
      test('$status uses the status as code and the backend message', () async {
        final result = await ApiAuthRepository(
          _dio(_FakeBackend(status, {'message': message})),
        ).getProfile();

        expect(result, isA<Failure>());
        final failure = result as Failure;
        expect(failure.code, status);
        expect(failure.message, message);
      });
    }

    test('falls back to a default message when the body has none', () async {
      final failure =
          await ApiAuthRepository(_dio(_FakeBackend(403))).getProfile() as Failure<Object?>;

      expect(failure.code, 403);
      expect(failure.message, 'You do not have permission');
    });

    test('a command error without a result body is a failure', () async {
      final failure =
          await ApiDeviceRepository(
                _dio(_FakeBackend(404, {'message': 'Device not found'})),
              ).sendCommand(1, DeviceCommand.on)
              as Failure<Object?>;

      expect(failure.code, 404);
    });

    test('an unreachable server has no status code', () async {
      final failure = await ApiAuthRepository(_dio(_UnreachableBackend())).getProfile() as Failure;

      expect(failure.code, isNull);
      expect(failure.message, 'Cannot reach the server. Check your connection.');
    });
  });
}
