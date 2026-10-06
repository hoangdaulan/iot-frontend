import 'package:gp1/core/utils/converters/date_time_converter.dart';
import 'package:gp1/data/models/device_action.dart';

/// Query parameters of `GET /api/devices/control-history`. All are optional.
class DeviceHistoryQuery {
  const DeviceHistoryQuery({
    this.deviceId,
    this.action,
    this.result,
    this.query,
    this.utcOffsetMinutes,
    this.from,
    this.to,
    this.page,
    this.size,
  });

  final int? deviceId;
  final DeviceActionType? action;
  final DeviceActionResult? result;

  /// A leading part of `yyyy/MM/dd HH:mm:ss`; matches the actions inside that period.
  final String? query;

  /// Offset east of UTC in minutes, so the backend reads a time search in the user's zone.
  final int? utcOffsetMinutes;

  final DateTime? from;
  final DateTime? to;

  /// 0-based.
  final int? page;
  final int? size;

  Map<String, String> toQueryParameters() => {
    if (deviceId != null) 'deviceId': '$deviceId',
    if (action != null) 'action': action!.wireValue,
    if (result != null) 'result': result!.wireValue,
    if ((query?.trim() ?? '').isNotEmpty) ...{
      'q': query!.trim(),
      if (utcOffsetMinutes != null) 'utcOffset': '$utcOffsetMinutes',
    },
    if (from != null) 'from': const DateTimeConverter().toJson(from!),
    if (to != null) 'to': const DateTimeConverter().toJson(to!),
    if (page != null) 'page': '$page',
    if (size != null) 'size': '$size',
  };
}
