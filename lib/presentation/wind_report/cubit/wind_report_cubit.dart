import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/wind_warning_report.dart';
import 'package:gp1/data/repositories/sensor_repository.dart';

class WindReportState {
  const WindReportState({this.isLoading = true, this.report, this.failure});

  final bool isLoading;

  /// The warnings of every day of the current month, once loaded.
  final WindWarningReport? report;
  final Failure? failure;

  WindReportState copyWith({bool? isLoading, WindWarningReport? report, Failure? failure}) {
    return WindReportState(
      isLoading: isLoading ?? this.isLoading,
      report: report ?? this.report,
      failure: failure,
    );
  }
}

/// The Wind Report screen: how many wind warnings each day of the current month had.
class WindReportCubit extends Cubit<WindReportState> {
  WindReportCubit(this._sensorRepository) : super(const WindReportState());

  final SensorRepository _sensorRepository;

  /// Loads the report of the current month (the backend's default), or reloads it.
  Future<void> load() async {
    final result = await _sensorRepository.getWindWarnings();
    if (isClosed) return;
    switch (result) {
      case Success(data: final report):
        emit(WindReportState(isLoading: false, report: report));
      case Failure():
        emit(state.copyWith(isLoading: false, failure: result));
    }
  }
}
