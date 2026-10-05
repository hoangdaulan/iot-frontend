// Contract test against a running backend (the docker compose stack with seeds). Skipped unless
// LIVE_API_URL is set:
//
//   LIVE_API_URL=http://localhost:8080 fvm flutter test test/integration/live_backend_test.dart
@TestOn('vm')
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/core/auth/auth_interceptor.dart';
import 'package:gp1/core/base/local_data_base.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/core/di/injection.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/dto/device_history_query.dart';
import 'package:gp1/data/models/dto/login_request.dart';
import 'package:gp1/data/models/dto/sensor_history_query.dart';
import 'package:gp1/data/models/dto/update_profile_request.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/user.dart';
import 'package:gp1/data/repositories/api/api_auth_repository.dart';
import 'package:gp1/data/repositories/api/api_device_repository.dart';
import 'package:gp1/data/repositories/api/api_sensor_repository.dart';

import '../helpers/fakes.dart';

void main() {
  final baseUrl = Platform.environment['LIVE_API_URL'];
  final skip = baseUrl == null ? 'LIVE_API_URL not set' : null;

  late InMemoryLocalDataBase storage;
  late Dio dio;

  setUp(() {
    storage = InMemoryLocalDataBase();
    getIt.registerSingleton<LocalDataBase>(storage);
    dio = Dio(BaseOptions(baseUrl: baseUrl ?? '', receiveTimeout: const Duration(seconds: 30)))
      ..interceptors.add(AuthInterceptor());
  });
  tearDown(() => getIt.reset());

  Future<void> signIn() async {
    final login = await ApiAuthRepository(
      dio,
    ).login(const LoginRequest(username: 'admin', password: '123456'));
    storage.accessToken = login.dataOrNull!.accessToken;
  }

  test('auth: login, wrong password, profile, profile update', () async {
    final auth = ApiAuthRepository(dio);

    final wrong =
        await auth.login(const LoginRequest(username: 'admin', password: 'nope')) as Failure;
    expect(wrong.code, 401);
    expect(wrong.message, 'Invalid email or password');

    final noToken = await auth.getProfile();
    expect((noToken as Failure).code, 401);

    final login = await auth.login(const LoginRequest(username: 'admin', password: '123456'));
    expect(login.dataOrNull?.user.role, UserRole.admin);
    storage.accessToken = login.dataOrNull!.accessToken;

    final profile = await auth.getProfile();
    expect(profile.dataOrNull?.email, 'admin@myiot.local');

    final phone = '+84 ${DateTime.now().millisecondsSinceEpoch % 1000000}';
    final updated = await auth.updateProfile(UpdateProfileRequest(phone: phone));
    expect(updated.dataOrNull?.phone, phone);
    expect(updated.dataOrNull?.github, profile.dataOrNull?.github);
  }, skip: skip);

  test('sensors: list, latest and history parse', () async {
    await signIn();
    final sensors = ApiSensorRepository(dio);

    expect((await sensors.getSensors()).dataOrNull?.map((s) => s.type), SensorType.values);

    final latest = (await sensors.getLatestSensorData()).dataOrNull!;
    expect(latest.data.keys, containsAll(SensorType.values));
    expect(latest.deviceStatus, isNot(DeviceStatus.unknown));

    final history = (await sensors.getSensorHistory(
      const SensorHistoryQuery(type: SensorType.humidity, size: 50),
    )).dataOrNull!;
    expect(history.totalElements, greaterThan(50));
    expect(history.toReadings(), hasLength(50));
    expect(history.toReadings().every((r) => r.type == SensorType.humidity), isTrue);
  }, skip: skip);

  test(
    'devices: control history parses; a command without an ESP32 times out',
    () async {
      await signIn();
      final devices = ApiDeviceRepository(dio);

      final page = (await devices.getControlHistory(const DeviceHistoryQuery(size: 5))).dataOrNull!;
      expect(page.content, hasLength(5));
      expect(page.content.first.deviceName, 'ESP32');

      final command = await devices.sendCommand(DeviceCommand.off);
      expect(command.dataOrNull?.status, DeviceActionResult.timeout);
    },
    skip: skip,
    timeout: const Timeout(Duration(seconds: 40)),
  );
}
