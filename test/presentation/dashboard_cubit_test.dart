import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/mock/mock_devices.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/device_action_history_item.dart';
import 'package:gp1/data/models/dto/device_command_result.dart';
import 'package:gp1/data/models/dto/device_history_query.dart';
import 'package:gp1/data/models/dto/latest_sensor_data_response.dart';
import 'package:gp1/data/models/dto/page_response.dart';
import 'package:gp1/data/models/dto/sensor_data_entry.dart';
import 'package:gp1/data/models/dto/sensor_history_query.dart';
import 'package:gp1/data/models/dto/sensor_history_response.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/repositories/device_repository.dart';
import 'package:gp1/data/repositories/mock/mock_device_repository.dart';
import 'package:gp1/data/repositories/mock/mock_sensor_repository.dart';
import 'package:gp1/data/repositories/sensor_repository.dart';
import 'package:gp1/presentation/dashboard/cubit/dashboard_cubit.dart';
import 'package:gp1/presentation/sensors/models/sensor_series.dart';

/// Device repository whose command response is set per test.
class _ScriptedDeviceRepository implements DeviceRepository {
  _ScriptedDeviceRepository(this.commandResult);

  final Result<DeviceCommandResult> commandResult;
  final _inner = MockDeviceRepository();

  @override
  Future<Result<List<Device>>> getDevices() => _inner.getDevices();

  @override
  Future<Result<DeviceCommandResult>> sendCommand(int deviceId, DeviceCommand command) async =>
      commandResult;

  @override
  Future<Result<PageResponse<DeviceActionHistoryItem>>> getControlHistory(
    DeviceHistoryQuery query,
  ) => _inner.getControlHistory(query);
}

/// Sensor repository that counts latest-data calls and returns a scripted response.
class _ScriptedSensorRepository implements SensorRepository {
  final _inner = MockSensorRepository();
  var latestCalls = 0;
  LatestSensorDataResponse latest = const LatestSensorDataResponse();
  SensorHistoryQuery? lastHistoryQuery;

  @override
  Future<Result<List<Sensor>>> getSensors() => _inner.getSensors();

  @override
  Future<Result<SensorHistoryResponse>> getSensorHistory(SensorHistoryQuery query) {
    lastHistoryQuery = query;
    return _inner.getSensorHistory(query);
  }

  @override
  Future<Result<LatestSensorDataResponse>> getLatestSensorData() async {
    latestCalls++;
    return Success(latest);
  }
}

const _ledOn = Device(id: 1, name: 'LED 1', type: 'LED', status: DeviceStatus.on);

bool _isLedOn(DashboardCubit cubit) => cubit.state.devices.firstWhere((d) => d.id == 1).isOn;

void main() {
  setUp(resetMockDevices);

  test('loadDashboard shows the device list, today series and statuses from the latest data', () async {
    final sensors = _ScriptedSensorRepository()
      ..latest = const LatestSensorDataResponse(devices: [_ledOn]);
    final cubit = DashboardCubit(sensors, MockDeviceRepository());

    await cubit.loadDashboard();

    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.series.keys, SensorType.values);
    expect(cubit.state.devices.map((d) => d.name), ['LED 1', 'LED 2', 'LED 3']);
    expect(_isLedOn(cubit), isTrue);
    expect(sensors.latestCalls, 1);
    final today = DateTime.now();
    expect(sensors.lastHistoryQuery?.from, DateTime(today.year, today.month, today.day));
    for (final reading in cubit.state.series.of(SensorType.temperature).readings) {
      expect(reading.timestamp.day, today.day);
    }
  });

  group('setDeviceOn', () {
    test('updates the LED once the command succeeds', () async {
      final cubit = DashboardCubit(MockSensorRepository(), MockDeviceRepository());
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
          MockSensorRepository(),
          _ScriptedDeviceRepository(
            Success(
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
      mockDeviceStatuses[1] = DeviceStatus.on;
      final cubit = DashboardCubit(
        MockSensorRepository(),
        _ScriptedDeviceRepository(const Failure(code: 403, message: 'You do not have permission')),
      );
      await cubit.loadDashboard();

      await cubit.setDeviceOn(1, false);

      expect(_isLedOn(cubit), isTrue);
      expect(cubit.state.failure?.message, 'You do not have permission');
    });

    test('falls back to a generic message when the backend sends none', () async {
      final cubit = DashboardCubit(
        MockSensorRepository(),
        _ScriptedDeviceRepository(
          const Success(
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
    test('appends newer readings and takes the reported LED status', () async {
      final sensors = _ScriptedSensorRepository();
      final cubit = DashboardCubit(sensors, MockDeviceRepository());
      await cubit.loadDashboard();
      final before = cubit.state.series.of(SensorType.temperature).readings.length;
      final now = DateTime.now().add(const Duration(minutes: 1));
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

    test('ignores readings that are not newer than what is shown', () async {
      final sensors = _ScriptedSensorRepository();
      final cubit = DashboardCubit(sensors, MockDeviceRepository());
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

    test('reflects the last command when using the mock repositories', () async {
      final cubit = DashboardCubit(MockSensorRepository(), MockDeviceRepository());
      await cubit.loadDashboard();
      final before = {
        for (final type in SensorType.values) type: cubit.state.series.of(type).readings.length,
      };

      await cubit.setDeviceOn(1, true);
      await cubit.refreshLatestSensorData();

      for (final type in SensorType.values) {
        expect(cubit.state.series.of(type).readings.length, before[type]! + 1);
      }
      expect(_isLedOn(cubit), isTrue);
      expect(cubit.state.failure, isNull);
    });
  });
}
