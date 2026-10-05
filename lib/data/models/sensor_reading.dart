import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gp1/data/models/sensor.dart';

part 'sensor_reading.freezed.dart';

/// Frontend read model for one measurement together with its sensor type, which the tables,
/// filters and charts group by. Built from the sensor-data DTOs (see `SensorHistoryResponse`).
@freezed
abstract class SensorReading with _$SensorReading {
  const SensorReading._();

  const factory SensorReading({
    required int id,
    required SensorType type,
    required double value,
    required DateTime timestamp,

    /// Not included in the sensor-data API responses.
    int? sensorId,
  }) = _SensorReading;

  String get unit => type.unit;
}
