import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gp1/core/utils/converters/date_time_converter.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/dto/user_info.dart';

part 'device_action_history_item.freezed.dart';
part 'device_action_history_item.g.dart';

/// One row of `GET /api/devices/control-history`: a `DeviceAction` joined with its device's
/// name, the device status it produced and the backend's message.
@freezed
abstract class DeviceActionHistoryItem with _$DeviceActionHistoryItem {
  @JsonSerializable(converters: [DateTimeConverter()])
  const factory DeviceActionHistoryItem({
    required int id,
    required int deviceId,
    required String deviceName,
    required DeviceActionType action,
    @JsonKey(unknownEnumValue: DeviceActionResult.unknown) required DeviceActionResult result,
    required DateTime timestamp,

    /// Device status after the action.
    @JsonKey(unknownEnumValue: DeviceStatus.unknown) DeviceStatus? status,
    String? message,

    /// The user who sent the command; null when that user has been deleted.
    UserInfo? user,
  }) = _DeviceActionHistoryItem;

  factory DeviceActionHistoryItem.fromJson(Map<String, dynamic> json) =>
      _$DeviceActionHistoryItemFromJson(json);
}
