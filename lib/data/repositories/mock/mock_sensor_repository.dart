import 'dart:math' as math;

import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/mock/mock_devices.dart';
import 'package:gp1/data/mock/mock_search.dart';
import 'package:gp1/data/mock/mock_sensor_data.dart';
import 'package:gp1/data/mock/mock_sensors.dart';
import 'package:gp1/data/models/dto/latest_sensor_data_response.dart';
import 'package:gp1/data/models/dto/sensor_data_entry.dart';
import 'package:gp1/data/models/dto/sensor_history_query.dart';
import 'package:gp1/data/models/dto/sensor_history_response.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_reading.dart';
import 'package:gp1/data/models/sensor_search_field.dart';
import 'package:gp1/data/repositories/sensor_repository.dart';

class MockSensorRepository implements SensorRepository {
  @override
  Future<Result<List<Sensor>>> getSensors() async => const Success(mockSensors);

  @override
  Future<Result<SensorHistoryResponse>> getSensorHistory(SensorHistoryQuery query) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final from = query.from;
    final to = query.to;

    // A window starting today is served by the live "today" dataset; anything else is cut
    // from the year-long history dataset.
    final source = from != null && !from.isBefore(startOfToday)
        ? generateTodaySensorReadings()
        : generateSensorHistory();

    final readings = source
        .where((r) => query.type == null || r.type == query.type)
        .where((r) => from == null || !r.timestamp.isBefore(from))
        .where((r) => to == null || !r.timestamp.isAfter(to))
        .where((r) => query.value == null || r.value == query.value)
        .where(_searchMatcher(query))
        .toList();

    final page = query.page ?? 0;
    final size = query.size ?? 20;
    final pageReadings = readings.skip(page * size).take(size).toList();

    return Success(
      SensorHistoryResponse(
        data: {
          for (final type in SensorType.values)
            type: [for (final r in pageReadings.where((r) => r.type == type)) _entryOf(r)],
        },
        page: page,
        pageSize: size,
        totalElements: readings.length,
        totalPages: (readings.length / size).ceil(),
      ),
    );
  }

  /// Mirrors the backend `filter`/`q` search so the mock behaves like the real API.
  static bool Function(SensorReading) _searchMatcher(SensorHistoryQuery query) {
    final field = query.searchField ?? SensorSearchField.all;
    final text = (query.searchQuery ?? '').trim();

    bool bySensor(SensorReading r) {
      final sensor = mockSensorOf(r.type);
      return sensor.id == int.tryParse(text) ||
          sensor.name.toLowerCase().contains(text.toLowerCase());
    }

    final valueRange = _valueRange(text);
    bool byValue(SensorReading r) =>
        valueRange != null && r.value >= valueRange.$1 && r.value < valueRange.$2;

    final timeRange = mockTimePrefixRange(text);
    bool byTime(SensorReading r) =>
        timeRange != null &&
        !r.timestamp.isBefore(timeRange.$1) &&
        r.timestamp.isBefore(timeRange.$2);

    if (field == SensorSearchField.all) {
      if (text.isEmpty) return (_) => true;
      return (r) => bySensor(r) || byValue(r) || byTime(r);
    }
    if (text.isEmpty) {
      return field == SensorSearchField.sensor || field == SensorSearchField.time
          ? (_) => true
          : (r) => r.type.name == field.wireValue;
    }
    return switch (field) {
      SensorSearchField.sensor => bySensor,
      SensorSearchField.time => byTime,
      _ => (r) => r.type.name == field.wireValue && byValue(r),
    };
  }

  /// Values starting with the typed number: `28` is 28 up to 29, `28.5` is 28.5 up to 28.6.
  static (double, double)? _valueRange(String text) {
    final value = double.tryParse(text);
    if (value == null || !value.isFinite) return null;
    final decimals = text.contains('.') ? text.split('.').last.length : 0;
    final step = 1 / math.pow(10, decimals);
    return text.startsWith('-') ? (value - step, value) : (value, value + step);
  }

  @override
  Future<Result<LatestSensorDataResponse>> getLatestSensorData() async {
    return Success(
      LatestSensorDataResponse(
        data: {for (final r in generateLatestSensorReadings()) r.type: _entryOf(r)},
        deviceStatus: mockDeviceStatuses[mockDevice.id],
        devices: currentMockDevices(),
      ),
    );
  }

  static SensorDataEntry _entryOf(SensorReading reading) => SensorDataEntry(
    id: reading.id,
    value: reading.value,
    timestamp: reading.timestamp,
    unit: mockSensorOf(reading.type).unit,
  );
}
