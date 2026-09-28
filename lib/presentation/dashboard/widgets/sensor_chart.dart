import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gp1/data/models/sensor_reading.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:intl/intl.dart';

class SensorChart extends StatelessWidget {
  const SensorChart({
    super.key,
    required this.title,
    required this.unit,
    required this.color,
    this.dataPoints = const [],
    this.readings,
    this.formatPattern,
  });

  final String title;
  final String unit;
  final Color color;
  final List<FlSpot> dataPoints;
  final List<SensorReading>? readings;
  final String? formatPattern;

  @override
  Widget build(BuildContext context) {
    // If time-series readings are provided, use them; otherwise fallback to dataPoints
    final isUsingReadings = readings != null;
    final List<SensorReading> sortedReadings = isUsingReadings
        ? (List<SensorReading>.from(readings!)..sort((a, b) => a.timestamp.compareTo(b.timestamp)))
        : [];

    final spots = isUsingReadings
        ? List<FlSpot>.generate(
            sortedReadings.length,
            (index) => FlSpot(index.toDouble(), sortedReadings[index].value),
          )
        : dataPoints;

    if (spots.isEmpty) {
      return Container(
        height: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ColorName.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ColorName.gray5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChartHeader(title: title, unit: unit, color: color),
            const Expanded(
              child: Center(
                child: Text(
                  'No data available',
                  style: TextStyle(color: ColorName.labelSecondary),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final rangeY = maxY - minY;
    final padding = rangeY == 0 ? (maxY == 0 ? 1.0 : maxY * 0.1) : rangeY * 0.15;

    final minX = spots.first.x;
    final maxX = spots.length > 1 ? spots.last.x : spots.first.x + 1;
    final rangeX = maxX - minX;

    final double bottomInterval = isUsingReadings
        ? (rangeX / 4).clamp(1.0, double.infinity)
        : 4.0;

    final double horizontalInterval = rangeY == 0 ? 1.0 : rangeY / 4;

    final timeFormatter = DateFormat(formatPattern ?? 'dd/MM HH:mm');

    return Container(
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
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: ColorName.gray5,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: const TextStyle(fontSize: 10, color: ColorName.labelSecondary),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: bottomInterval,
                      getTitlesWidget: (value, meta) {
                        if (isUsingReadings) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= sortedReadings.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              timeFormatter.format(sortedReadings[idx].timestamp),
                              style: const TextStyle(fontSize: 10, color: ColorName.labelSecondary),
                            ),
                          );
                        } else {
                          final hour = value.toInt();
                          if (hour < 0 || hour > 24) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${hour.toString().padLeft(2, '0')}:00',
                              style: const TextStyle(fontSize: 10, color: ColorName.labelSecondary),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: minX,
                maxX: maxX,
                minY: (minY - padding).clamp(0, double.infinity),
                maxY: maxY + padding,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: spots.length > 2,
                    curveSmoothness: 0.3,
                    color: color,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: spots.length <= 15),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.2),
                          color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => ColorName.labelPrimary,
                    getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                      if (isUsingReadings) {
                        final idx = spot.x.toInt();
                        if (idx >= 0 && idx < sortedReadings.length) {
                          final ts = timeFormatter.format(sortedReadings[idx].timestamp);
                          return LineTooltipItem(
                            '$ts\n${spot.y.toStringAsFixed(1)} $unit',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }
                      }
                      final hour = spot.x.toInt();
                      final minute = ((spot.x - hour) * 60).toInt();
                      return LineTooltipItem(
                        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}\n${spot.y.toStringAsFixed(1)} $unit',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
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

class _ChartHeader extends StatelessWidget {
  const _ChartHeader({
    required this.title,
    required this.unit,
    required this.color,
  });

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
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
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
