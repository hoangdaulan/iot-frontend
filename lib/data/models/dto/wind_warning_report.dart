import 'package:freezed_annotation/freezed_annotation.dart';

part 'wind_warning_report.freezed.dart';
part 'wind_warning_report.g.dart';

/// The number of wind warnings of one day.
@freezed
abstract class WindWarningDay with _$WindWarningDay {
  const WindWarningDay._();

  const factory WindWarningDay({
    /// `yyyy-MM-dd`, Vietnam time.
    required String date,
    required int count,
  }) = _WindWarningDay;

  factory WindWarningDay.fromJson(Map<String, dynamic> json) => _$WindWarningDayFromJson(json);

  /// The day of the month, 1 to 31.
  int get day => int.parse(date.substring(8, 10));
}

/// Response of `GET /api/reports/wind-warnings`: every day of a month with its number of wind
/// warnings, that is, readings at or above [threshold] km/h (the times LED WIND was on).
@freezed
abstract class WindWarningReport with _$WindWarningReport {
  const WindWarningReport._();

  const factory WindWarningReport({
    /// `yyyy-MM`.
    required String month,
    @Default(300) double threshold,
    @Default(0) int total,
    @Default([]) List<WindWarningDay> days,
  }) = _WindWarningReport;

  factory WindWarningReport.fromJson(Map<String, dynamic> json) =>
      _$WindWarningReportFromJson(json);

  /// The day with the most warnings, or null when the month has none.
  WindWarningDay? get busiestDay {
    WindWarningDay? best;
    for (final day in days) {
      if (day.count > 0 && (best == null || day.count > best.count)) best = day;
    }
    return best;
  }

  /// Days with at least one warning.
  int get daysWithWarnings => days.where((d) => d.count > 0).length;
}
