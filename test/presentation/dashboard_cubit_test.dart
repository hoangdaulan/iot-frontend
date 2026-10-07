import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/dto/device_command_result.dart';
import 'package:gp1/data/models/dto/latest_sensor_data_response.dart';
import 'package:gp1/data/models/dto/sensor_data_entry.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/presentation/dashboard/cubit/dashboard_cubit.dart';
import 'package:gp1/presentation/sensors/models/sensor_series.dart';

import '../helpers/fake_device_repository.dart';
import '../helpers/fake_sensor_repository.dart';

const _ledOn = Device(id: 1, name: 'LED 1', type: 'LED', status: DeviceStatus.on);

bool _isLedOn(DashboardCubit cubit) => cubit.state.devices.firstWhere((d) => d.id == 1).isOn;

void main() {
  test('loadDashboard shows the device list, the last 24 hours and the latest statuses', () async {
    final sensors = FakeSensorRepository()
      ..latest = const LatestSensorDataResponse(devices: [_ledOn]);
    final cubit = DashboardCubit(sensors, FakeDeviceRepository());

    await cubit.loadDashboard();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.series.keys, SensorType.values);
    expect(cubit.state.devices.map((d) => d.name), ['LED 1', 'LED 2', 'LED 3']);
    expect(_isLedOn(cubit), isTrue);
    expect(sensors.latestCalls, 1);

    // The query is the last 24 hours in 5-minute averages.
    final query = sensors.lastQuery!;
    final expectedStart = DateTime.now().subtract(const Duration(hours: 24));
    expect(query.from!.difference(expectedStart).abs(), lessThan(const Duration(seconds: 5)));
    expect(query.bucket, const Duration(minutes: 5));
    expect(cubit.state.windowStart, query.from);

    final temperature = cubit.state.series.of(SensorType.temperature).readings;
    expect(temperature.length, inInclusiveRange(280, 290), reason: '24 h / 5 min ≈ 288 windows');
    // A window is stamped with its start, so the first may begin up to one window early.
    for (final reading in temperature) {
      expect(reading.timestamp.isBefore(query.from!.subtract(const Duration(minutes: 5))), isFalse);
    }
    final gaps = [
      for (var i = 1; i < temperature.length; i++)
        temperature[i].timestamp.difference(temperature[i - 1].timestamp),
    ];
    expect(gaps.every((gap) => gap >= const Duration(minutes: 5)), isTrue);
  });

  group('setDeviceOn', () {
    test('updates the LED once the command succeeds', () async {
      final cubit = DashboardCubit(FakeSensorRepository(), FakeDeviceRepository());
      await cubit.loadDashboard();
      expect(_isLedOn(cubit), isFalse);

      await cubit.setDeviceOn(1, true);
      expect(_isLedOn(cubit), isTrue);

      await cubit.setDeviceOn(1, false);
      expect(_isLedOn(cubit), isFalse);
      expect(cubit.state.failure, isNull);
    });

    for (final status in [DeviceActionResult.failed, DeviceActionResult.timeout]) {
      test('keeps the previous state and reports the message on ${status.name}', () async {
        final cubit = DashboardCubit(
          FakeSensorRepository(),
          FakeDeviceRepository(
            commandResult: Success(
              DeviceCommandResult(
                deviceId: 1,
                command: DeviceCommand.on,
                status: status,
                message: 'Device did not respond in time',
              ),
            ),
          ),
        );
        await cubit.loadDashboard();

        await cubit.setDeviceOn(1, true);

        expect(_isLedOn(cubit), isFalse);
        expect(cubit.state.failure?.message, 'Device did not respond in time');
      });
    }

    test('keeps the previous state when the request itself fails', () async {
      final devices = FakeDeviceRepository(
        commandResult: const Failure(code: 403, message: 'You do not have permission'),
      )..statuses[1] = DeviceStatus.on;
      final cubit = DashboardCubit(FakeSensorRepository(), devices);
      await cubit.loadDashboard();

      await cubit.setDeviceOn(1, false);

      expect(_isLedOn(cubit), isTrue);
      expect(cubit.state.failure?.message, 'You do not have permission');
    });

    test('falls back to a generic message when the backend sends none', () async {
      final cubit = DashboardCubit(
        FakeSensorRepository(),
        FakeDeviceRepository(
          commandResult: const Success(
            DeviceCommandResult(
              deviceId: 1,
              command: DeviceCommand.off,
              status: DeviceActionResult.timeout,
            ),
          ),
        ),
      );
      await cubit.loadDashboard();

      await cubit.setDeviceOn(1, false);

      expect(cubit.state.failure?.message, 'Device did not accept OFF (Timeout)');
    });
  });

  group('refreshLatestSensorData', () {
    test('appends readings a window later and takes the reported LED status', () async {
      final sensors = FakeSensorRepository();
      final cubit = DashboardCubit(sensors, FakeDeviceRepository());
      await cubit.loadDashboard();
      final readings = cubit.state.series.of(SensorType.temperature).readings;
      final before = readings.length;
      final now = readings.last.timestamp.add(const Duration(minutes: 6));
      sensors.latest = LatestSensorDataResponse(
        data: {
          SensorType.temperature: SensorDataEntry(id: 900, value: 31.4, timestamp: now),
          SensorType.light: SensorDataEntry(id: 901, value: 812, timestamp: now),
        },
        devices: [_ledOn],
      );

      await cubit.refreshLatestSensorData();

      expect(sensors.latestCalls, 2);
      final temperature = cubit.state.series.of(SensorType.temperature);
      expect(temperature.readings.length, before + 1);
      expect(temperature.latestValue, 31.4);
      expect(cubit.state.series.of(SensorType.light).latestValue, 812);
      expect(_isLedOn(cubit), isTrue);
    });

    test('a reading inside the last window replaces it instead of adding a point', () async {
      final sensors = FakeSensorRepository();
      final cubit = DashboardCubit(sensors, FakeDeviceRepository());
      await cubit.loadDashboard();
      final before = cubit.state.series.of(SensorType.temperature).readings;
      final soon = before.last.timestamp.add(const Duration(minutes: 1));
      sensors.latest = LatestSensorDataResponse(
        data: {SensorType.temperature: SensorDataEntry(id: 903, value: 40.2, timestamp: soon)},
      );

      await cubit.refreshLatestSensorData();

      final after = cubit.state.series.of(SensorType.temperature).readings;
      expect(after.length, before.length);
      expect(after.last.value, 40.2);
      expect(after.last.timestamp, soon);
    });

    test('ignores readings that are not newer than what is shown', () async {
      final sensors = FakeSensorRepository();
      final cubit = DashboardCubit(sensors, FakeDeviceRepository());
      await cubit.loadDashboard();
      final series = cubit.state.series.of(SensorType.humidity);
      sensors.latest = LatestSensorDataResponse(
        data: {
          SensorType.humidity: SensorDataEntry(
            id: 902,
            value: 99,
            timestamp: series.readings.last.timestamp,
          ),
        },
      );

      await cubit.refreshLatestSensorData();

      expect(cubit.state.series.of(SensorType.humidity).readings.length, series.readings.length);
    });

    test('reflects the last command in the statuses the backend reports', () async {
      final devices = FakeDeviceRepository();
      final cubit = DashboardCubit(FakeSensorRepository(devices: devices), devices);
      await cubit.loadDashboard();
      final before = {
        for (final type in SensorType.values) type: cubit.state.series.of(type).readings.length,
      };

      await cubit.setDeviceOn(1, true);
      await cubit.refreshLatestSensorData();

      for (final type in SensorType.values) {
        // The fresh reading either replaces the last window or follows it.
        expect(
          cubit.state.series.of(type).readings.length,
          inInclusiveRange(before[type]!, before[type]! + 1),
        );
      }
      expect(_isLedOn(cubit), isTrue);
      expect(cubit.state.failure, isNull);
    });
  });
}
