import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/latest_sensor_data_response.dart';
import 'package:gp1/data/models/dto/sensor_history_query.dart';
import 'package:gp1/data/models/dto/sensor_history_response.dart';
import 'package:gp1/data/models/dto/wind_warning_report.dart';
import 'package:gp1/data/models/sensor.dart';

abstract interface class SensorRepository {
  /// `GET /api/sensors`
  Future<Result<List<Sensor>>> getSensors();

  /// `GET /api/sensor-data/history`
  Future<Result<SensorHistoryResponse>> getSensorHistory(SensorHistoryQuery query);

  /// `GET /api/sensor-data/latest`
  Future<Result<LatestSensorDataResponse>> getLatestSensorData();

  /// `GET /api/reports/wind-warnings`: the warnings of each day of [month] (`yyyy-MM`; the
  /// current month when null).
  Future<Result<WindWarningReport>> getWindWarnings({String? month});

  /// `PUT /api/settings/wind-threshold`: sets the wind speed (a whole number of km/h from 0 to
  /// 500) from which the warning LED lights up and a reading counts as a warning. Returns the
  /// saved value.
  Future<Result<int>> setWindThreshold(int threshold);
}
