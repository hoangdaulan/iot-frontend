import 'package:gp1/core/utils/converters/date_time_converter.dart';
import 'package:gp1/data/models/device_action.dart';

/// Query parameters of `GET /api/devices/control-history`. All are optional.
class DeviceHistoryQuery {
  const DeviceHistoryQuery({
    this.deviceId,
    this.action,
    this.result,
    this.query,
    this.startTime,
    this.endTime,
    this.page,
    this.size,
  });

  final int? deviceId;
  final DeviceActionType? action;
  final DeviceActionResult? result;

  /// A leading part of `yyyy/MM/dd HH:mm:ss`; matches the actions inside that period.
  final String? query;

  /// Bounds of the time range; a missing bound leaves that side open.
  final DateTime? startTime;
  final DateTime? endTime;

  /// 0-based.
  final int? page;
  final int? size;

  Map<String, String> toQueryParameters() => {
    if (deviceId != null) 'deviceId': '$deviceId',
    if (action != null) 'action': action!.wireValue,
    if (result != null) 'result': result!.wireValue,
    if ((query?.trim() ?? '').isNotEmpty) 'q': query!.trim(),
    if (startTime != null) 'startTime': const DateTimeConverter().toJson(startTime!),
    if (endTime != null) 'endTime': const DateTimeConverter().toJson(endTime!),
    if (page != null) 'page': '$page',
    if (size != null) 'size': '$size',
  };
}
