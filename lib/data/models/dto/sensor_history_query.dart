import 'package:gp1/core/utils/converters/date_time_converter.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_search_field.dart';

/// Query parameters of `GET /api/sensor-data/history`. All are optional.
class SensorHistoryQuery {
  const SensorHistoryQuery({
    this.type,
    this.from,
    this.to,
    this.value,
    this.bucket,
    this.searchField,
    this.searchQuery,
    this.utcOffsetMinutes,
    this.page,
    this.size,
  });

  final SensorType? type;

  /// Bounds of the documented `timeRange` parameter.
  final DateTime? from;
  final DateTime? to;

  /// Exact measured value to search for.
  final double? value;

  /// Averages each sensor over windows of this length (whole minutes); every returned entry is
  /// then a window, stamped with its start.
  final Duration? bucket;

  /// What [searchQuery] is matched against. All: any of the others; sensor: id or name; a sensor
  /// type: values starting with the typed number (28 is 28.0 - 28.99); time: a leading part of
  /// `yyyy/MM/dd HH:mm:ss`.
  final SensorSearchField? searchField;
  final String? searchQuery;

  /// Offset east of UTC in minutes, so the backend reads a time search in the user's zone.
  final int? utcOffsetMinutes;

  /// 0-based, like control history.
  final int? page;
  final int? size;

  /// `timeRange` is sent as an ISO-8601 interval (`<from>/<to>`, `..` for an open end). The
  /// report does not fix this encoding yet.
  Map<String, String> toQueryParameters() => {
    if (type != null) 'type': type!.name,
    if (from != null || to != null) 'timeRange': '${_format(from)}/${_format(to)}',
    if (value != null) 'value': '$value',
    if (bucket != null) 'bucket': '${bucket!.inMinutes}m',
    if (searchField != null && searchField != SensorSearchField.all)
      'filter': searchField!.wireValue,
    if ((searchQuery?.trim() ?? '').isNotEmpty) 'q': searchQuery!.trim(),
    if ((searchField == SensorSearchField.time || searchField == SensorSearchField.all) &&
        utcOffsetMinutes != null)
      'utcOffset': '$utcOffsetMinutes',
    if (page != null) 'page': '$page',
    if (size != null) 'size': '$size',
  };

  static String _format(DateTime? time) =>
      time == null ? '..' : const DateTimeConverter().toJson(time);
}
