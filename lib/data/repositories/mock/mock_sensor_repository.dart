import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/mock/mock_devices.dart';
import 'package:gp1/data/mock/mock_sensor_data.dart';
import 'package:gp1/data/mock/mock_sensors.dart';
import 'package:gp1/data/models/dto/latest_sensor_data_response.dart';
import 'package:gp1/data/models/dto/sensor_data_entry.dart';
import 'package:gp1/data/models/dto/sensor_history_query.dart';
import 'package:gp1/data/models/dto/sensor_history_response.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_reading.dart';
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

  @override
  Future<Result<LatestSensorDataResponse>> getLatestSensorData() async {
    return Success(
      LatestSensorDataResponse(
        data: {for (final r in generateLatestSensorReadings()) r.type: _entryOf(r)},
        deviceStatus: mockLedStatus,
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
