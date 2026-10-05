import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/app/constants/app_constants.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/dto/latest_sensor_data_response.dart';
import 'package:gp1/data/models/dto/sensor_history_query.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/repositories/device_repository.dart';
import 'package:gp1/data/repositories/sensor_repository.dart';
import 'package:gp1/presentation/sensors/models/sensor_series.dart';

class DashboardState {
  final bool isLoading;

  /// Today's readings per sensor type.
  final Map<SensorType, SensorSeries> series;

  /// Status of the ESP32's LED, the system's only controllable output.
  final DeviceStatus ledStatus;
  final Failure? failure;

  const DashboardState({
    this.isLoading = true,
    this.series = const {},
    this.ledStatus = DeviceStatus.unknown,
    this.failure,
  });

  bool get isLedOn => ledStatus == DeviceStatus.on;

  DashboardState copyWith({
    bool? isLoading,
    Map<SensorType, SensorSeries>? series,
    DeviceStatus? ledStatus,
    Failure? failure,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      series: series ?? this.series,
      ledStatus: ledStatus ?? this.ledStatus,
      failure: failure,
    );
  }
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._sensorRepository, this._deviceRepository) : super(const DashboardState());

  final SensorRepository _sensorRepository;
  final DeviceRepository _deviceRepository;

  var _isCommandInFlight = false;
  var _isRefreshing = false;

  /// Loads today's history for the charts, then the latest values and LED status.
  Future<void> loadDashboard() async {
    final now = DateTime.now();
    final historyResult = await _sensorRepository.getSensorHistory(
      SensorHistoryQuery(
        from: DateTime(now.year, now.month, now.day),
        size: AppConstants.historyFetchSize,
      ),
    );
    final latestResult = await _sensorRepository.getLatestSensorData();

    final series = SensorSeries.group(historyResult.dataOrNull?.toReadings() ?? const []);
    emit(
      _withLatest(
        state.copyWith(isLoading: false, series: series),
        latestResult.dataOrNull,
      ).copyWith(failure: _firstFailure([historyResult, latestResult])),
    );
  }

  /// Fetches the newest values (and LED status) and appends them to today's series.
  Future<void> refreshLatestSensorData() async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    final result = await _sensorRepository.getLatestSensorData();
    _isRefreshing = false;

    switch (result) {
      case Success(data: final latest):
        emit(_withLatest(state, latest));
      case Failure():
        emit(state.copyWith(failure: result));
    }
  }

  /// Sends the command and only updates the LED once the backend confirms it. On `FAILED` or
  /// `TIMEOUT` the LED keeps its previous status and the backend message is reported.
  Future<void> setLedOn(bool isOn) async {
    if (_isCommandInFlight) return;

    _isCommandInFlight = true;
    final command = isOn ? DeviceCommand.on : DeviceCommand.off;
    final result = await _deviceRepository.sendCommand(command);
    _isCommandInFlight = false;

    switch (result) {
      case Success(data: final commandResult) when commandResult.isSuccess:
        emit(state.copyWith(ledStatus: command.resultingStatus));
      case Success(data: final commandResult):
        emit(
          state.copyWith(
            failure: Failure(
              message:
                  commandResult.message ??
                  'Device did not accept ${command.label} (${commandResult.status.label})',
            ),
          ),
        );
      case Failure():
        emit(state.copyWith(failure: result));
    }
  }

  /// Appends readings newer than the last one shown per type, and takes the reported LED status.
  DashboardState _withLatest(DashboardState current, LatestSensorDataResponse? latest) {
    if (latest == null) return current;

    final readings = [for (final series in current.series.values) ...series.readings];
    for (final reading in latest.toReadings()) {
      final last = current.series.of(reading.type).readings.lastOrNull;
      if (last == null || reading.timestamp.isAfter(last.timestamp)) readings.add(reading);
    }
    return current.copyWith(series: SensorSeries.group(readings), ledStatus: latest.deviceStatus);
  }

  Failure? _firstFailure(List<Result<Object?>> results) =>
      results.whereType<Failure<Object?>>().firstOrNull;
}
