import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/data/mock/mock_data.dart';
import 'package:gp1/data/models/sensor_reading.dart';

class DashboardState {
  final bool isLoading;
  final double currentTemperature;
  final double currentHumidity;
  final double currentLight;
  final double temperatureTrend;
  final double humidityTrend;
  final double lightTrend;
  final List<FlSpot> temperatureChartData;
  final List<FlSpot> humidityChartData;
  final List<FlSpot> lightChartData;
  final bool temperatureSensorOn;
  final bool humiditySensorOn;
  final bool lightSensorOn;

  const DashboardState({
    this.isLoading = true,
    this.currentTemperature = 0,
    this.currentHumidity = 0,
    this.currentLight = 0,
    this.temperatureTrend = 0,
    this.humidityTrend = 0,
    this.lightTrend = 0,
    this.temperatureChartData = const [],
    this.humidityChartData = const [],
    this.lightChartData = const [],
    this.temperatureSensorOn = true,
    this.humiditySensorOn = true,
    this.lightSensorOn = false,
  });

  DashboardState copyWith({
    bool? isLoading,
    double? currentTemperature,
    double? currentHumidity,
    double? currentLight,
    double? temperatureTrend,
    double? humidityTrend,
    double? lightTrend,
    List<FlSpot>? temperatureChartData,
    List<FlSpot>? humidityChartData,
    List<FlSpot>? lightChartData,
    bool? temperatureSensorOn,
    bool? humiditySensorOn,
    bool? lightSensorOn,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      currentTemperature: currentTemperature ?? this.currentTemperature,
      currentHumidity: currentHumidity ?? this.currentHumidity,
      currentLight: currentLight ?? this.currentLight,
      temperatureTrend: temperatureTrend ?? this.temperatureTrend,
      humidityTrend: humidityTrend ?? this.humidityTrend,
      lightTrend: lightTrend ?? this.lightTrend,
      temperatureChartData: temperatureChartData ?? this.temperatureChartData,
      humidityChartData: humidityChartData ?? this.humidityChartData,
      lightChartData: lightChartData ?? this.lightChartData,
      temperatureSensorOn: temperatureSensorOn ?? this.temperatureSensorOn,
      humiditySensorOn: humiditySensorOn ?? this.humiditySensorOn,
      lightSensorOn: lightSensorOn ?? this.lightSensorOn,
    );
  }
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardState());

  void loadDashboard() {
    final readings = MockData.generateTodaySensorReadings();

    final tempReadings = readings.where((r) => r.type == SensorType.temperature).toList();
    final humReadings = readings.where((r) => r.type == SensorType.humidity).toList();
    final lightReadings = readings.where((r) => r.type == SensorType.light).toList();

    // Current values (latest reading)
    final currentTemp = tempReadings.isNotEmpty ? tempReadings.last.value : 0.0;
    final currentHum = humReadings.isNotEmpty ? humReadings.last.value : 0.0;
    final currentLight = lightReadings.isNotEmpty ? lightReadings.last.value : 0.0;

    // Trends (difference between last two readings)
    final tempTrend = tempReadings.length >= 2
        ? tempReadings.last.value - tempReadings[tempReadings.length - 2].value
        : 0.0;
    final humTrend = humReadings.length >= 2
        ? humReadings.last.value - humReadings[humReadings.length - 2].value
        : 0.0;
    final lightTrend = lightReadings.length >= 2
        ? lightReadings.last.value - lightReadings[lightReadings.length - 2].value
        : 0.0;

    // Chart data: convert to FlSpot (x = hour as double, y = value)
    List<FlSpot> toChartData(List<SensorReading> data) {
      return data.map((r) {
        final x = r.timestamp.hour + r.timestamp.minute / 60.0;
        return FlSpot(x, r.value);
      }).toList();
    }

    emit(state.copyWith(
      isLoading: false,
      currentTemperature: currentTemp,
      currentHumidity: currentHum,
      currentLight: currentLight,
      temperatureTrend: double.parse(tempTrend.toStringAsFixed(1)),
      humidityTrend: double.parse(humTrend.toStringAsFixed(1)),
      lightTrend: double.parse(lightTrend.toStringAsFixed(1)),
      temperatureChartData: toChartData(tempReadings),
      humidityChartData: toChartData(humReadings),
      lightChartData: toChartData(lightReadings),
    ));
  }

  void toggleDevice(String type) {
    switch (type) {
      case 'temperature':
        emit(state.copyWith(temperatureSensorOn: !state.temperatureSensorOn));
      case 'humidity':
        emit(state.copyWith(humiditySensorOn: !state.humiditySensorOn));
      case 'light':
        emit(state.copyWith(lightSensorOn: !state.lightSensorOn));
    }
  }
}
