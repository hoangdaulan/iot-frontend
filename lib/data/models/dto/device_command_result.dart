import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gp1/data/models/device_action.dart';

part 'device_command_result.freezed.dart';
part 'device_command_result.g.dart';

/// Response of `POST /api/devices/{id}/command`, returned once the ESP32 confirms the command
/// over MQTT (`SUCCESS`/`FAILED`) or stops responding (`TIMEOUT`, sent with HTTP 504).
@freezed
abstract class DeviceCommandResult with _$DeviceCommandResult {
  const DeviceCommandResult._();

  const factory DeviceCommandResult({
    required int deviceId,
    required DeviceCommand command,
    @JsonKey(unknownEnumValue: DeviceActionResult.unknown) required DeviceActionResult status,
    String? message,
  }) = _DeviceCommandResult;

  factory DeviceCommandResult.fromJson(Map<String, dynamic> json) =>
      _$DeviceCommandResultFromJson(json);

  bool get isSuccess => status == DeviceActionResult.success;
}
