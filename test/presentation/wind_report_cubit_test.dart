import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/wind_warning_report.dart';
import 'package:gp1/presentation/wind_report/cubit/wind_report_cubit.dart';

import '../helpers/fake_sensor_repository.dart';

void main() {
  test('load shows the report of the current month', () async {
    final repository = FakeSensorRepository();
    final cubit = WindReportCubit(repository);
    expect(cubit.state.isLoading, isTrue);

    await cubit.load();

    expect(repository.windWarningCalls, 1);
    expect(cubit.state.isLoading, isFalse);
    expect(cubit.state.report?.days, hasLength(31));
    expect(cubit.state.failure, isNull);
  });

  test('a failed load keeps the report that was shown and reports the failure', () async {
    final repository = FakeSensorRepository();
    final cubit = WindReportCubit(repository);
    await cubit.load();
    final before = cubit.state.report;

    repository.windWarnings = const Failure<WindWarningReport>(message: 'Network error');
    await cubit.load();

    expect(cubit.state.report, before);
    expect(cubit.state.failure?.message, 'Network error');
    expect(cubit.state.isLoading, isFalse);
  });
}
