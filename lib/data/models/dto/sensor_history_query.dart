import 'package:gp1/core/utils/converters/date_time_converter.dart';
import 'package:gp1/data/models/sensor.dart';

/// Query parameters of `GET /api/sensor-data/history`. All are optional.
class SensorHistoryQuery {
  const SensorHistoryQuery({this.type, this.from, this.to, this.value, this.page, this.size});

  final SensorType? type;

  /// Bounds of the documented `timeRange` parameter.
  final DateTime? from;
  final DateTime? to;

  /// Exact measured value to search for.
  final double? value;

  /// 0-based, like control history.
  final int? page;
  final int? size;

  /// `timeRange` is sent as an ISO-8601 interval (`<from>/<to>`, `..` for an open end). The
  /// report does not fix this encoding yet.
  Map<String, String> toQueryParameters() => {
    if (type != null) 'type': type!.name,
    if (from != null || to != null) 'timeRange': '${_format(from)}/${_format(to)}',
    if (value != null) 'value': '$value',
    if (page != null) 'page': '$page',
    if (size != null) 'size': '$size',
  };

  static String _format(DateTime? time) =>
      time == null ? '..' : const DateTimeConverter().toJson(time);
}
