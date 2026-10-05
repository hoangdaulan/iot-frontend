import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gp1/core/utils/converters/date_time_converter.dart';

part 'sensor.freezed.dart';
part 'sensor.g.dart';

enum SensorType {
  temperature('Temperature', '°C'),
  humidity('Humidity', '%'),
  light('Light', 'lux');

  final String label;

  /// Display unit used when a reading carries no unit of its own.
  final String unit;

  const SensorType(this.label, this.unit);
}

@freezed
abstract class Sensor with _$Sensor {
  @JsonSerializable(converters: [DateTimeConverter()])
  const factory Sensor({
    required int id,
    required String name,
    required SensorType type,
    required String unit,

    /// Free-form operating status. The backend has not defined its values yet.
    String? status,
    String? mqttTopic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Sensor;

  factory Sensor.fromJson(Map<String, dynamic> json) => _$SensorFromJson(json);
}
