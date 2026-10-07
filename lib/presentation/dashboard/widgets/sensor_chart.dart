import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gp1/core/utils/extensions/date_time_extension.dart';
import 'package:gp1/data/models/sensor_reading.dart';
import 'package:gp1/generated/colors.gen.dart';

/// Chart x for [time]: hours since [origin], with the minutes and seconds as a fraction. Counting
/// from the start of the window, not the hour of day, keeps a 24-hour window that crosses
/// midnight in order, and the seconds keep readings of one minute apart.
double hoursSince(DateTime origin, DateTime time) => time.difference(origin).inSeconds / 3600;

/// The points of [readings] for a chart whose x-axis counts hours from [origin].
List<FlSpot> trendSpots(Iterable<SensorReading> readings, {required DateTime origin}) => [
  for (final reading in readings) FlSpot(hoursSince(origin, reading.timestamp), reading.value),
];

/// The moment an x of [hoursSince] stands for.
DateTime timeAt(DateTime origin, double hours) =>
    origin.add(Duration(seconds: (hours * 3600).round()));

/// The tooltip of a point: its date and time, then its value with the unit.
String tooltipLabel(DateTime origin, FlSpot spot, String unit) =>
    '${timeAt(origin, spot.x).toFormatString(pattern: 'dd/MM/yyyy HH:mm')}\n'
    '${spot.y.toStringAsFixed(1)} $unit';

/// The y-axis bounds around values from [minY] to [maxY]. Each side gets a margin of
/// [marginFraction] of the data range, but at least [minMargin], so a line that barely moves is not
/// stretched over the whole height and a line that moves a lot does not touch the edges. The lower
/// bound never goes below zero.
({double min, double max}) yAxisRange(
  double minY,
  double maxY, {
  double marginFraction = 0.15,
  double minMargin = 0,
}) {
  final range = maxY - minY;
  final fallback = maxY == 0 ? 1.0 : maxY.abs() * 0.1;
  final margin = range == 0
      ? (fallback > minMargin ? fallback : minMargin)
      : (range * marginFraction > minMargin ? range * marginFraction : minMargin);
  return (min: minY - margin < 0 ? 0 : minY - margin, max: maxY + margin);
}

/// A line chart of one sensor. Its x-axis counts hours from [origin] (see [trendSpots]), shown as
/// clock time; the tooltip shows the date and time of a point together with its value.
class SensorChart extends StatelessWidget {
  const SensorChart({
    super.key,
    required this.title,
    required this.unit,
    required this.color,
    required this.origin,
    this.dataPoints = const [],
    this.yMarginFraction = 0.15,
    this.yMinMargin = 0,
  });

  final String title;
  final String unit;
  final Color color;

  /// The moment x = 0 stands for.
  final DateTime origin;
  final List<FlSpot> dataPoints;

  /// Room above and below the data on the y-axis, as a fraction of the data range and as a floor
  /// in the unit of the values. More room makes the line look softer. See [yAxisRange].
  final double yMarginFraction;
  final double yMinMargin;

  @override
  Widget build(BuildContext context) {
    final spots = dataPoints;

    if (spots.isEmpty) {
      return _ChartCard(
        color: color,
        height: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChartHeader(title: title, unit: unit, color: color),
            const Expanded(
              child: Center(
                child: Text('No data available', style: TextStyle(color: ColorName.labelSecondary)),
              ),
            ),
          ],
        ),
      );
    }

    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final yRange = yAxisRange(minY, maxY, marginFraction: yMarginFraction, minMargin: yMinMargin);

    final minX = spots.first.x;
    final maxX = spots.length > 1 ? spots.last.x : spots.first.x + 1;
    final rangeX = maxX - minX;

    // Both axes are labelled from the data actually shown, a quarter of the range apart.
    final bottomInterval = (rangeX / 4).clamp(1 / 60, double.infinity);
    // Whole numbers would repeat (27, 27, 27) when the axis barely spans a few units.
    final axisSpan = yRange.max - yRange.min;
    final yDecimals = axisSpan >= 5 ? 0 : 1;
    final horizontalInterval = axisSpan / 4;

    const labelStyle = TextStyle(fontSize: 10, color: ColorName.labelSecondary);

    return _ChartCard(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartHeader(title: title, unit: unit, color: color),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: horizontalInterval,
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: ColorName.gray5, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) =>
                          Text(value.toStringAsFixed(yDecimals), style: labelStyle),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: bottomInterval,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          timeAt(origin, value).toFormatString(pattern: 'HH:mm'),
                          style: labelStyle,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: minX,
                maxX: maxX,
                minY: yRange.min,
                maxY: yRange.max,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: spots.length > 2,
                    curveSmoothness: 0.3,
                    preventCurveOverShooting: true,
                    color: color,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: spots.length <= 15),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => ColorName.labelPrimary,
                    getTooltipItems: (touchedSpots) => [
                      for (final spot in touchedSpots)
                        LineTooltipItem(
                          tooltipLabel(origin, spot, unit),
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              duration: const Duration(milliseconds: 300),
            ),
          ),
        ],
      ),
    );
  }
}

/// The white rounded card both the empty and the filled chart sit in.
class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.color, required this.child, this.height});

  final Color color;
  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorName.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorName.gray5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ChartHeader extends StatelessWidget {
  const _ChartHeader({required this.title, required this.unit, required this.color});

  final String title;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(
          '$title ($unit)',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ColorName.labelPrimary,
          ),
        ),
      ],
    );
  }
}
