import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/dto/sensor_data_entry.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_reading.dart';

part 'latest_sensor_data_response.freezed.dart';
part 'latest_sensor_data_response.g.dart';

/// Response of `GET /api/sensor-data/latest`: the newest measurement per sensor type and the
/// current LED status of the single ESP32. A type is absent if no data was received for it yet.
@freezed
abstract class LatestSensorDataResponse with _$LatestSensorDataResponse {
  const LatestSensorDataResponse._();

  const factory LatestSensorDataResponse({
    @Default({}) Map<SensorType, SensorDataEntry> data,
    @JsonKey(unknownEnumValue: DeviceStatus.unknown) DeviceStatus? deviceStatus,
  }) = _LatestSensorDataResponse;

  factory LatestSensorDataResponse.fromJson(Map<String, dynamic> json) =>
      _$LatestSensorDataResponseFromJson(json);

  List<SensorReading> toReadings() =>
      flattenSensorData(data.map((type, entry) => MapEntry(type, [entry])));
}
