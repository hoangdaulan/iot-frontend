import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gp1/core/utils/converters/date_time_converter.dart';

part 'device.freezed.dart';
part 'device.g.dart';

enum DeviceStatus {
  @JsonValue('ON')
  on,
  @JsonValue('OFF')
  off,
  unknown,
}

/// A controllable device (actuator) that receives ON/OFF commands over MQTT.
@freezed
abstract class Device with _$Device {
  const Device._();

  @JsonSerializable(converters: [DateTimeConverter()])
  const factory Device({
    required int id,
    required String name,

    /// Device kind, e.g. `LED`. Kept as a string because the backend has not fixed the set of
    /// device types yet. Sensor kinds (`temperature`, ...) are `SensorType`, not device types.
    required String type,
    @JsonKey(unknownEnumValue: DeviceStatus.unknown)
    @Default(DeviceStatus.unknown)
    DeviceStatus status,
    String? mqttTopic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Device;

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);

  bool get isOn => status == DeviceStatus.on;
}
