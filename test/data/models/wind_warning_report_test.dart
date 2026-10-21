import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/dto/wind_warning_report.dart';

void main() {
  test('WindWarningReport reads the days and finds the busiest one', () {
    final report = WindWarningReport.fromJson({
      'month': '2026-10',
      'threshold': 300,
      'total': 9,
      'days': [
        {'date': '2026-10-01', 'count': 2},
        {'date': '2026-10-02', 'count': 0},
        {'date': '2026-10-03', 'count': 7},
      ],
    });

    expect(report.month, '2026-10');
    expect(report.threshold, 300);
    expect(report.days.map((d) => d.day), [1, 2, 3]);
    expect(report.busiestDay?.date, '2026-10-03');
    expect(report.daysWithWarnings, 2);
  });

  test('a month without warnings has no busiest day', () {
    final report = WindWarningReport.fromJson({
      'month': '2026-10',
      'days': [
        {'date': '2026-10-01', 'count': 0},
      ],
    });
    expect(report.busiestDay, isNull);
    expect(report.daysWithWarnings, 0);
    expect(report.threshold, 300);
  });

  test('only the warning LED is automatic', () {
    expect(const Device(id: 3, name: 'LED WIND', type: 'Warning Led').isAutomatic, isTrue);
    expect(const Device(id: 1, name: 'LED 1', type: 'LED').isAutomatic, isFalse);
  });
}
