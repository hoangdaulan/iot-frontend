import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gp1/data/models/dto/sensor_data_entry.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_reading.dart';

part 'sensor_history_response.freezed.dart';
part 'sensor_history_response.g.dart';

/// Response of `GET /api/sensor-data/history`: one page of measurements (newest first), grouped
/// by sensor type. `page` is 0-based; the totals count individual measurements.
@freezed
abstract class SensorHistoryResponse with _$SensorHistoryResponse {
  const SensorHistoryResponse._();

  const factory SensorHistoryResponse({
    @Default({}) Map<SensorType, List<SensorDataEntry>> data,
    @Default(0) int page,
    @Default(20) int pageSize,
    @Default(0) int totalElements,
    @Default(0) int totalPages,
  }) = _SensorHistoryResponse;

  factory SensorHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$SensorHistoryResponseFromJson(json);

  /// All measurements as frontend read models, newest first.
  List<SensorReading> toReadings() => flattenSensorData(data);
}
