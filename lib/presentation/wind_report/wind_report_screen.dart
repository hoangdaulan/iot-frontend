import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/core/di/injection.dart';
import 'package:gp1/core/loading/loading_service.dart';
import 'package:gp1/core/utils/extensions/snack_bar_extension.dart';
import 'package:gp1/data/models/dto/wind_warning_report.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/widgets/app_loading.dart';
import 'package:gp1/presentation/widgets/my_app_bar.dart';
import 'package:gp1/presentation/wind_report/cubit/wind_report_cubit.dart';

class WindReportScreen extends StatelessWidget {
  const WindReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<WindReportCubit>()..load(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: MyAppBar(
            title: const Text('Wind Report'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => context.read<WindReportCubit>().load().withLoading(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: const WindReportView(),
        ),
      ),
    );
  }
}

class WindReportView extends StatelessWidget {
  const WindReportView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WindReportCubit, WindReportState>(
      listener: (context, state) => context.handleFailure(state.failure),
      builder: (context, state) {
        final report = state.report;
        if (state.isLoading && report == null) return const AppLoading(size: 40);
        if (report == null) {
          return const Center(
            child: Text('No data available', style: TextStyle(color: ColorName.labelSecondary)),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wind warnings per day - ${report.month}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ColorName.labelPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'A warning is a wind speed reading of ${report.threshold.toStringAsFixed(0)} km/h '
                'or more, the moments LED WIND is on.',
                style: const TextStyle(fontSize: 13, color: ColorName.labelSecondary),
              ),
              const SizedBox(height: 16),
              _Summary(report: report),
              const SizedBox(height: 16),
              WindWarningChart(report: report),
            ],
          ),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.report});

  final WindWarningReport report;

  @override
  Widget build(BuildContext context) {
    final busiest = report.busiestDay;
    final items = [
      _SummaryItem('Total warnings', '${report.total}', ColorName.red),
      _SummaryItem(
        'Days with warnings',
        '${report.daysWithWarnings} / ${report.days.length}',
        ColorName.blue,
      ),
      _SummaryItem(
        'Busiest day',
        busiest == null
            ? '-'
            : '${busiest.date.substring(8)}/${busiest.date.substring(5, 7)} (${busiest.count})',
        ColorName.orange,
      ),
    ];
    return Wrap(spacing: 12, runSpacing: 12, children: items);
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorName.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorName.gray5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: ColorName.labelSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

/// A column chart with one bar per day of the month: its height is the number of warnings.
class WindWarningChart extends StatelessWidget {
  const WindWarningChart({super.key, required this.report});

  final WindWarningReport report;

  @override
  Widget build(BuildContext context) {
    final maxCount = report.days.fold<int>(0, (m, d) => d.count > m ? d.count : m);
    // A round upper bound, so the top grid line is a clean number.
    final maxY = maxCount == 0 ? 10.0 : _niceCeil(maxCount.toDouble());
    const labelStyle = TextStyle(fontSize: 10, color: ColorName.labelSecondary);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: ColorName.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorName.gray5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SizedBox(
                width: 4,
                height: 16,
                child: DecoratedBox(decoration: BoxDecoration(color: ColorName.red)),
              ),
              SizedBox(width: 8),
              Text(
                'Warnings (times)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ColorName.labelPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 320,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: ColorName.gray5, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: maxY / 5,
                      getTitlesWidget: (value, meta) =>
                          Text(value.toStringAsFixed(0), style: labelStyle),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('${value.toInt()}', style: labelStyle),
                      ),
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => ColorName.labelPrimary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = report.days[groupIndex];
                      return BarTooltipItem(
                        '${day.date.substring(8)}/${day.date.substring(5, 7)}\n'
                        '${day.count} warnings',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
                barGroups: [
                  for (final day in report.days)
                    BarChartGroupData(
                      x: day.day,
                      barRods: [
                        BarChartRodData(
                          toY: day.count.toDouble(),
                          width: 10,
                          color: ColorName.red,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Center(child: Text('Day of the month', style: labelStyle)),
        ],
      ),
    );
  }

  /// The next "round" number (1, 2, 5 times a power of ten) at or above [value].
  static double _niceCeil(double value) {
    var step = 1.0;
    while (step * 10 < value) {
      step *= 10;
    }
    for (final m in [1.0, 2.0, 5.0, 10.0]) {
      if (step * m >= value) return step * m;
    }
    return step * 10;
  }
}
