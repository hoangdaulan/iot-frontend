import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/latest_sensor_data_response.dart';
import 'package:gp1/data/models/dto/sensor_history_query.dart';
import 'package:gp1/data/models/dto/sensor_history_response.dart';
import 'package:gp1/data/models/sensor.dart';

abstract interface class SensorRepository {
  /// `GET /api/sensors`
  Future<Result<List<Sensor>>> getSensors();

  /// `GET /api/sensor-data/history`
  Future<Result<SensorHistoryResponse>> getSensorHistory(SensorHistoryQuery query);

  /// `GET /api/sensor-data/latest`
  Future<Result<LatestSensorDataResponse>> getLatestSensorData();
}
