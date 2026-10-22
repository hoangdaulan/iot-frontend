import 'package:dio/dio.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/latest_sensor_data_response.dart';
import 'package:gp1/data/models/dto/sensor_history_query.dart';
import 'package:gp1/data/models/dto/sensor_history_response.dart';
import 'package:gp1/data/models/dto/wind_warning_report.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/remote/api_failure.dart';
import 'package:gp1/data/repositories/sensor_repository.dart';

class ApiSensorRepository implements SensorRepository {
  ApiSensorRepository(this._dio);

  final Dio _dio;

  @override
  Future<Result<List<Sensor>>> getSensors() => guardRequest(() async {
    final res = await _dio.get<List<dynamic>>('/api/sensors');
    return [for (final json in res.data!) Sensor.fromJson(json as Map<String, dynamic>)];
  });

  @override
  Future<Result<SensorHistoryResponse>> getSensorHistory(SensorHistoryQuery query) =>
      guardRequest(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/api/sensor-data/history',
          queryParameters: query.toQueryParameters(),
        );
        return SensorHistoryResponse.fromJson(res.data!);
      });

  @override
  Future<Result<LatestSensorDataResponse>> getLatestSensorData() => guardRequest(() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/sensor-data/latest');
    return LatestSensorDataResponse.fromJson(res.data!);
  });

  @override
  Future<Result<int>> setWindThreshold(int threshold) => guardRequest(() async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/settings/wind-threshold',
      data: {'threshold': threshold},
    );
    return (res.data!['threshold'] as num).toInt();
  });

  @override
  Future<Result<WindWarningReport>> getWindWarnings({String? month}) => guardRequest(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/reports/wind-warnings',
      queryParameters: {'month': ?month},
    );
    return WindWarningReport.fromJson(res.data!);
  });
}
