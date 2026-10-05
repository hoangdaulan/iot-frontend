import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gp1/core/utils/converters/date_time_converter.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_reading.dart';

part 'sensor_data_entry.freezed.dart';
part 'sensor_data_entry.g.dart';

/// One measurement as the sensor-data endpoints return it. The sensor type is given by the
/// enclosing `data` key, not by the entry itself.
@freezed
abstract class SensorDataEntry with _$SensorDataEntry {
  const SensorDataEntry._();

  @JsonSerializable(converters: [DateTimeConverter()])
  const factory SensorDataEntry({
    required int id,
    required double value,
    required DateTime timestamp,
    String? unit,
  }) = _SensorDataEntry;

  factory SensorDataEntry.fromJson(Map<String, dynamic> json) => _$SensorDataEntryFromJson(json);

  SensorReading toReading(SensorType type) =>
      SensorReading(id: id, type: type, value: value, timestamp: timestamp);
}

/// Flattens a `{ "temperature": ..., "humidity": ..., "light": ... }` grouping into readings,
/// newest first.
List<SensorReading> flattenSensorData(Map<SensorType, Iterable<SensorDataEntry>> data) {
  return [
    for (final MapEntry(key: type, value: entries) in data.entries)
      for (final entry in entries) entry.toReading(type),
  ]..sort((a, b) {
    final byTime = b.timestamp.compareTo(a.timestamp);
    return byTime != 0 ? byTime : a.type.index.compareTo(b.type.index);
  });
}
