import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gp1/core/utils/converters/date_time_converter.dart';
import 'package:gp1/data/models/device.dart';

part 'device_action.freezed.dart';
part 'device_action.g.dart';

/// Command sent to `POST /api/devices/{id}/command`.
enum DeviceCommand {
  @JsonValue('ON')
  on('ON'),
  @JsonValue('OFF')
  off('OFF');

  final String label;

  const DeviceCommand(this.label);

  DeviceStatus get resultingStatus => switch (this) {
    DeviceCommand.on => DeviceStatus.on,
    DeviceCommand.off => DeviceStatus.off,
  };
}

/// Action recorded in the control history.
enum DeviceActionType {
  @JsonValue('TURN_ON')
  turnOn('ON'),
  @JsonValue('TURN_OFF')
  turnOff('OFF');

  final String label;

  const DeviceActionType(this.label);

  /// Value of the `action` query parameter of the control history.
  String get wireValue => switch (this) {
    DeviceActionType.turnOn => 'TURN_ON',
    DeviceActionType.turnOff => 'TURN_OFF',
  };
}

/// Outcome of a device command, as confirmed (or not) by the ESP32 over MQTT.
enum DeviceActionResult {
  @JsonValue('SUCCESS')
  success('Success'),
  @JsonValue('FAILED')
  failed('Failed'),
  @JsonValue('TIMEOUT')
  timeout('Timeout'),
  @JsonValue('PENDING')
  pending('Pending'),
  unknown('Unknown');

  final String label;

  const DeviceActionResult(this.label);

  /// Value of the `result` query parameter of the control history.
  String get wireValue => name.toUpperCase();
}

/// One control operation on a device (control history entity).
@freezed
abstract class DeviceAction with _$DeviceAction {
  @JsonSerializable(converters: [DateTimeConverter()])
  const factory DeviceAction({
    required int id,
    required int deviceId,
    required DeviceActionType action,
    @JsonKey(unknownEnumValue: DeviceActionResult.unknown) required DeviceActionResult result,
    required DateTime timestamp,

    /// Null when the action was not triggered by a user (e.g. automation).
    int? userId,
  }) = _DeviceAction;

  factory DeviceAction.fromJson(Map<String, dynamic> json) => _$DeviceActionFromJson(json);
}
