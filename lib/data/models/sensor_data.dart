import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gp1/core/utils/converters/date_time_converter.dart';

part 'sensor_data.freezed.dart';
part 'sensor_data.g.dart';

/// A single measurement taken by the sensor identified by [sensorId].
///
/// See `SensorReading` for the history/read model that also carries the sensor type.
@freezed
abstract class SensorData with _$SensorData {
  @JsonSerializable(converters: [DateTimeConverter()])
  const factory SensorData({
    required int id,
    required int sensorId,
    required double value,
    required DateTime timestamp,
  }) = _SensorData;

  factory SensorData.fromJson(Map<String, dynamic> json) => _$SensorDataFromJson(json);
}
