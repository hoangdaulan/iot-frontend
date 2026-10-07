import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/latest_sensor_data_response.dart';
import 'package:gp1/data/models/dto/sensor_data_entry.dart';
import 'package:gp1/data/models/dto/sensor_history_query.dart';
import 'package:gp1/data/models/dto/sensor_history_response.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_reading.dart';
import 'package:gp1/data/repositories/sensor_repository.dart';

import 'fake_device_repository.dart';

/// A sensor repository for tests. It answers like the backend's history endpoint would for the
/// last 24 hours in 5-minute averages (289 windows per type, the newest starting now), applies
/// the type, time range and paging of the query, and records every query. It does not implement
/// the search of `filter`/`q`: that belongs to the backend and is tested there.
class FakeSensorRepository implements SensorRepository {
  /// The device repository whose LED states the latest-data call reports, if any.
  FakeSensorRepository({this.devices});

  final FakeDeviceRepository? devices;

  final queries = <SensorHistoryQuery>[];
  var latestCalls = 0;

  /// What the latest-data call returns; by default a reading of every type taken now, together
  /// with the states of [devices].
  LatestSensorDataResponse? latest;

  /// A failure to answer every history call with, instead of the data.
  Failure<SensorHistoryResponse>? historyFailure;

  SensorHistoryQuery? get lastQuery => queries.lastOrNull;

  late final List<SensorReading> _readings = _generate();

  List<SensorReading> _generate() {
    final now = DateTime.now();
    final readings = <SensorReading>[];
    var id = 1;
    for (var i = 0; i <= 288; i++) {
      final at = now.subtract(Duration(minutes: i * 5));
      for (final type in SensorType.values) {
        readings.add(
          SensorReading(
            id: id++,
            type: type,
            // Different per type and window, so a chart has something to draw.
            value: 20.0 + type.index * 10 + (i % 12),
            timestamp: at,
          ),
        );
      }
    }
    return readings;
  }

  @override
  Future<Result<List<Sensor>>> getSensors() async => const Success([]);

  @override
  Future<Result<SensorHistoryResponse>> getSensorHistory(SensorHistoryQuery query) async {
    queries.add(query);
    if (historyFailure != null) return historyFailure!;

    final from = query.from;
    final to = query.to;
    final matching = _readings
        .where((r) => query.type == null || r.type == query.type)
        .where((r) => from == null || !r.timestamp.isBefore(from))
        .where((r) => to == null || !r.timestamp.isAfter(to))
        .toList();

    final page = query.page ?? 0;
    final size = query.size ?? 20;
    final pageReadings = matching.skip(page * size).take(size).toList();
    return Success(
      SensorHistoryResponse(
        data: {
          for (final type in SensorType.values)
            type: [
              for (final r in pageReadings.where((r) => r.type == type))
                SensorDataEntry(id: r.id, value: r.value, timestamp: r.timestamp),
            ],
        },
        page: page,
        pageSize: size,
        totalElements: matching.length,
        totalPages: (matching.length / size).ceil(),
      ),
    );
  }

  @override
  Future<Result<LatestSensorDataResponse>> getLatestSensorData() async {
    latestCalls++;
    if (latest != null) return Success(latest!);

    final now = DateTime.now();
    return Success(
      LatestSensorDataResponse(
        data: {
          for (final type in SensorType.values)
            type: SensorDataEntry(
              id: 100000 + type.index,
              value: 25.0 + type.index,
              timestamp: now,
            ),
        },
        deviceStatus: devices?.statuses[1],
        devices: devices?.devices ?? const [],
      ),
    );
  }
}
