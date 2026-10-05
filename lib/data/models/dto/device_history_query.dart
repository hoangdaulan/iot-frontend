import 'package:gp1/core/utils/converters/date_time_converter.dart';

/// Query parameters of `GET /api/devices/control-history`. All are optional; there is only one
/// device, so no device filter is sent.
class DeviceHistoryQuery {
  const DeviceHistoryQuery({this.from, this.to, this.page, this.size});

  final DateTime? from;
  final DateTime? to;

  /// 0-based.
  final int? page;
  final int? size;

  Map<String, String> toQueryParameters() => {
    if (from != null) 'from': const DateTimeConverter().toJson(from!),
    if (to != null) 'to': const DateTimeConverter().toJson(to!),
    if (page != null) 'page': '$page',
    if (size != null) 'size': '$size',
  };
}
