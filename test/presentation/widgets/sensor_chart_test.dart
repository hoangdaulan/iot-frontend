import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_reading.dart';
import 'package:gp1/presentation/dashboard/widgets/sensor_chart.dart';

SensorReading _reading(int id, DateTime at, double value) =>
    SensorReading(id: id, type: SensorType.temperature, value: value, timestamp: at);

void main() {
  final origin = DateTime(2026, 10, 5, 15, 0);

  test('hoursSince counts from the origin, across midnight, with the seconds', () {
    expect(hoursSince(origin, DateTime(2026, 10, 5, 16, 30)), 1.5);
    expect(hoursSince(origin, DateTime(2026, 10, 6, 3, 0)), 12);
    expect(hoursSince(origin, DateTime(2026, 10, 6, 15, 0)), 24);
    expect(hoursSince(origin, DateTime(2026, 10, 5, 15, 0, 36)), closeTo(0.01, 1e-9));
  });

  test('trendSpots stays in order over a window that crosses midnight', () {
    final readings = [
      for (var h = 0; h <= 24; h += 4) _reading(h, origin.add(Duration(hours: h)), 20.0 + h),
    ];

    final xs = trendSpots(readings, origin: origin).map((spot) => spot.x).toList();

    expect(xs, [0, 4, 8, 12, 16, 20, 24]);
  });

  test('trendSpots keeps readings of the same minute apart', () {
    final readings = [
      for (var s = 0; s < 6; s++) _reading(s, DateTime(2026, 10, 5, 15, 1, s * 10), 26 + s * 0.1),
    ];

    final xs = trendSpots(readings, origin: origin).map((spot) => spot.x).toList();

    expect(xs.toSet(), hasLength(readings.length));
  });

  test('timeAt is the moment an x stands for', () {
    expect(timeAt(origin, 0), origin);
    expect(timeAt(origin, 9.5), DateTime(2026, 10, 6, 0, 30));
    expect(
      timeAt(origin, hoursSince(origin, DateTime(2026, 10, 6, 7, 5, 9))),
      DateTime(2026, 10, 6, 7, 5, 9),
    );
  });

  group('yAxisRange', () {
    test('adds a fraction of the data range on each side', () {
      final range = yAxisRange(20, 30);

      expect(range.min, closeTo(18.5, 1e-9));
      expect(range.max, closeTo(31.5, 1e-9));
    });

    test('a bigger fraction leaves more room', () {
      final range = yAxisRange(20, 30, marginFraction: 0.5);

      expect(range.min, 15);
      expect(range.max, 35);
    });

    test('a line that barely moves still gets the minimum margin', () {
      final range = yAxisRange(26.0, 26.4, marginFraction: 0.5, minMargin: 2);

      expect(range.min, 24);
      expect(range.max, closeTo(28.4, 1e-9));
    });

    test('a flat line gets a margin too', () {
      expect(yAxisRange(25, 25).min, lessThan(25));
      expect(yAxisRange(25, 25).max, greaterThan(25));
      expect(yAxisRange(25, 25, minMargin: 3), (min: 22.0, max: 28.0));
      expect(yAxisRange(0, 0), (min: 0.0, max: 1.0));
    });

    test('never goes below zero', () {
      expect(yAxisRange(1, 5, marginFraction: 0.5, minMargin: 2).min, 0);
    });
  });

  Widget chart(List<SensorReading> readings) => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 500,
        child: SensorChart(
          title: 'Temperature',
          unit: '°C',
          color: Colors.red,
          origin: origin,
          dataPoints: trendSpots(readings, origin: origin),
        ),
      ),
    ),
  );

  testWidgets('a full day of 5-minute averages renders with clock labels', (tester) async {
    final readings = [
      for (var i = 0; i <= 288; i++)
        _reading(i, origin.add(Duration(minutes: i * 5)), 20 + (i % 40) / 10),
    ];

    await tester.pumpWidget(chart(readings));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Temperature (°C)'), findsOneWidget);
    // The x-axis is labelled every 6 hours from the origin.
    expect(find.text('15:00'), findsWidgets);
    expect(find.text('21:00'), findsOneWidget);
    expect(find.text('03:00'), findsOneWidget);
  });

  testWidgets('an empty chart says there is no data', (tester) async {
    await tester.pumpWidget(chart(const []));

    expect(find.text('No data available'), findsOneWidget);
  });

  test('the tooltip shows the date and time of the point, then its value', () {
    final spot = FlSpot(hoursSince(origin, DateTime(2026, 10, 6, 7, 5)), 27.34);

    expect(tooltipLabel(origin, spot, '°C'), '06/10/2026 07:05\n27.3 °C');
  });
}
