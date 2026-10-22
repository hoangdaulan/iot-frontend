import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/app/constants/app_constants.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/wind_warning_report.dart';
import 'package:gp1/data/repositories/sensor_repository.dart';

class WindReportState {
  const WindReportState({this.isLoading = true, this.isSaving = false, this.report, this.failure});

  final bool isLoading;

  /// A new threshold is being saved.
  final bool isSaving;

  /// The warnings of every day of the current month, once loaded.
  final WindWarningReport? report;
  final Failure? failure;

  WindReportState copyWith({
    bool? isLoading,
    bool? isSaving,
    WindWarningReport? report,
    Failure? failure,
  }) {
    return WindReportState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      report: report ?? this.report,
      failure: failure,
    );
  }
}

/// The Wind Report screen: how many wind warnings each day of the current month had.
class WindReportCubit extends Cubit<WindReportState> {
  WindReportCubit(this._sensorRepository) : super(const WindReportState());

  final SensorRepository _sensorRepository;

  Timer? _liveTimer;
  var _isLoading = false;

  /// Loads the report of the current month (the backend's default), or reloads it, then keeps
  /// it up to date: every [AppConstants.liveRefreshInterval] the report is fetched again. A failed
  /// refresh of that kind stays silent; the next one tries again.
  Future<void> load() async {
    await _fetch(silent: false);
    if (isClosed) return;
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(AppConstants.liveRefreshInterval, (_) => _fetch(silent: true));
  }

  Future<void> _fetch({required bool silent}) async {
    if (_isLoading) return;
    _isLoading = true;
    final result = await _sensorRepository.getWindWarnings();
    _isLoading = false;
    if (isClosed) return;
    switch (result) {
      case Success(data: final report):
        // Same numbers as shown: nothing to redraw.
        if (silent && report == state.report) return;
        emit(WindReportState(isLoading: false, isSaving: state.isSaving, report: report));
      case Failure():
        if (silent) return;
        emit(state.copyWith(isLoading: false, failure: result));
    }
  }

  /// Saves a new warning threshold (km/h) and shows the report counted with it. Returns whether
  /// it was saved.
  Future<bool> saveThreshold(int threshold) async {
    if (state.isSaving) return false;
    emit(state.copyWith(isSaving: true));
    final result = await _sensorRepository.setWindThreshold(threshold);
    if (isClosed) return false;
    switch (result) {
      case Success():
        await _fetch(silent: false);
        if (!isClosed) emit(state.copyWith(isSaving: false));
        return true;
      case Failure():
        emit(state.copyWith(isSaving: false, failure: result));
        return false;
    }
  }

  @override
  Future<void> close() {
    _liveTimer?.cancel();
    return super.close();
  }
}
