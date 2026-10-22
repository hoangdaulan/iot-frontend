import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/app/constants/app_constants.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/wind_warning_report.dart';
import 'package:gp1/presentation/wind_report/cubit/wind_report_cubit.dart';

import '../helpers/fake_sensor_repository.dart';

void main() {
  test('load shows the report of the current month', () async {
    final repository = FakeSensorRepository();
    final cubit = WindReportCubit(repository);
    addTearDown(cubit.close);
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
    addTearDown(cubit.close);
    await cubit.load();
    final before = cubit.state.report;

    repository.windWarnings = const Failure<WindWarningReport>(message: 'Network error');
    await cubit.load();

    expect(cubit.state.report, before);
    expect(cubit.state.failure?.message, 'Network error');
    expect(cubit.state.isLoading, isFalse);
  });

  test('saveThreshold sends the value and shows the report counted with it', () async {
    final repository = FakeSensorRepository();
    final cubit = WindReportCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.report?.threshold, 300);

    final saved = await cubit.saveThreshold(250);

    expect(saved, isTrue);
    expect(repository.savedThresholds, [250]);
    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.report?.threshold, 250);
    expect(cubit.state.failure, isNull);
  });

  test('a refused threshold is reported and the old one stays', () async {
    final repository = FakeSensorRepository();
    final cubit = WindReportCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();
    repository.thresholdFailure = const Failure<int>(message: 'Invalid threshold');

    final saved = await cubit.saveThreshold(900);

    expect(saved, isFalse);
    expect(cubit.state.isSaving, isFalse);
    expect(cubit.state.failure?.message, 'Invalid threshold');
    expect(cubit.state.report?.threshold, 300);
  });

  test('the report is fetched again every interval, and quietly', () {
    fakeAsync((async) {
      final repository = FakeSensorRepository();
      final cubit = WindReportCubit(repository);
      cubit.load();
      async.flushMicrotasks();
      expect(repository.windWarningCalls, 1);

      async.elapse(AppConstants.liveRefreshInterval * 3);
      expect(repository.windWarningCalls, 4);

      // A failure of a refresh is not reported and the report stays.
      final shown = cubit.state.report;
      repository.windWarnings = const Failure<WindWarningReport>(message: 'Network error');
      async.elapse(AppConstants.liveRefreshInterval);
      expect(cubit.state.failure, isNull);
      expect(cubit.state.report, shown);

      // New numbers replace the report.
      repository.windWarnings = const Success(
        WindWarningReport(
          month: '2026-10',
          total: 9,
          days: [WindWarningDay(date: '2026-10-01', count: 9)],
        ),
      );
      async.elapse(AppConstants.liveRefreshInterval);
      expect(cubit.state.report?.total, 9);

      // Nothing is fetched once the cubit is closed.
      cubit.close();
      final calls = repository.windWarningCalls;
      async.elapse(AppConstants.liveRefreshInterval * 3);
      expect(repository.windWarningCalls, calls);
    });
  });
}
