import 'package:gp1/core/utils/converters/date_time_converter.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_search_field.dart';

/// Query parameters of `GET /api/sensor-data/history`. All are optional.
class SensorHistoryQuery {
  const SensorHistoryQuery({
    this.type,
    this.startTime,
    this.endTime,
    this.value,
    this.bucket,
    this.searchField,
    this.searchQuery,
    this.page,
    this.size,
  });

  final SensorType? type;

  /// Bounds of the time range; a missing bound leaves that side open. Sent as ISO-8601 instants.
  final DateTime? startTime;
  final DateTime? endTime;

  /// Exact measured value to search for.
  final double? value;

  /// Takes the maximum of each sensor over windows of this length (whole minutes); every returned entry is
  /// then a window, stamped with its start.
  final Duration? bucket;

  /// What [searchQuery] is matched against. All: any of the others; sensor: id or name; a sensor
  /// type: values starting with the typed number (28 is 28.0 - 28.99); time: a leading part of
  /// `yyyy/MM/dd HH:mm:ss`.
  final SensorSearchField? searchField;
  final String? searchQuery;

  /// 0-based, like control history.
  final int? page;
  final int? size;

  Map<String, String> toQueryParameters() => {
    if (type != null) 'type': type!.name,
    if (startTime != null) 'startTime': const DateTimeConverter().toJson(startTime!),
    if (endTime != null) 'endTime': const DateTimeConverter().toJson(endTime!),
    if (value != null) 'value': '$value',
    if (bucket != null) 'bucket': '${bucket!.inMinutes}m',
    if (searchField != null && searchField != SensorSearchField.all)
      'filter': searchField!.wireValue,
    if ((searchQuery?.trim() ?? '').isNotEmpty) 'q': searchQuery!.trim(),
    if (page != null) 'page': '$page',
    if (size != null) 'size': '$size',
  };
}
