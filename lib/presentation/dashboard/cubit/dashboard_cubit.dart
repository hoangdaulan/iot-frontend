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

  /// The controllable devices (LEDs) from the `devices` table, ordered by id.
  final List<Device> devices;
  final Failure? failure;

  const DashboardState({
    this.isLoading = true,
    this.series = const {},
    this.devices = const [],
    this.failure,
  });


  DashboardState copyWith({
    bool? isLoading,
    Map<SensorType, SensorSeries>? series,
    List<Device>? devices,
    Failure? failure,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      series: series ?? this.series,
      devices: devices ?? this.devices,
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

  /// Loads the device list and today's history for the charts, then the latest values and device
  /// statuses.
  Future<void> loadDashboard() async {
    final devicesResult = await _deviceRepository.getDevices();
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
        state.copyWith(
          isLoading: false,
          series: series,
          devices: devicesResult.dataOrNull ?? state.devices,
        ),
        latestResult.dataOrNull,
      ).copyWith(failure: _firstFailure([devicesResult, historyResult, latestResult])),
    );
  }

  /// Fetches the newest values (and device statuses) and appends them to today's series.
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

  /// Sends the command and only updates the device once the backend confirms it. On `FAILED` or
  /// `TIMEOUT` the device keeps its previous status and the backend message is reported.
  Future<void> setDeviceOn(int deviceId, bool isOn) async {
    if (_isCommandInFlight) return;

    _isCommandInFlight = true;
    final command = isOn ? DeviceCommand.on : DeviceCommand.off;
    final result = await _deviceRepository.sendCommand(deviceId, command);
    _isCommandInFlight = false;

    switch (result) {
      case Success(data: final commandResult) when commandResult.isSuccess:
        emit(state.copyWith(devices: _withStatus(deviceId, command.resultingStatus)));
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

  List<Device> _withStatus(int deviceId, DeviceStatus status) => [
    for (final device in state.devices)
      device.id == deviceId ? device.copyWith(status: status) : device,
  ];

  /// Appends readings newer than the last one shown per type, and takes the reported device
  /// statuses.
  DashboardState _withLatest(DashboardState current, LatestSensorDataResponse? latest) {
    if (latest == null) return current;

    final readings = [for (final series in current.series.values) ...series.readings];
    for (final reading in latest.toReadings()) {
      final last = current.series.of(reading.type).readings.lastOrNull;
      if (last == null || reading.timestamp.isAfter(last.timestamp)) readings.add(reading);
    }
    final statuses = {for (final device in latest.devices) device.id: device.status};
    return current.copyWith(
      series: SensorSeries.group(readings),
      devices: [
        for (final device in current.devices)
          device.copyWith(status: statuses[device.id] ?? device.status),
      ],
    );
  }

  Failure? _firstFailure(List<Result<Object?>> results) =>
      results.whereType<Failure<Object?>>().firstOrNull;
}
