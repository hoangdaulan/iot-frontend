import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_reading.dart';
import 'package:gp1/presentation/dashboard/widgets/sensor_chart.dart';

SensorReading _reading(int id, DateTime at, double value) =>
    SensorReading(id: id, type: SensorType.temperature, value: value, timestamp: at);

void main() {
  test('dayHour counts the seconds, so readings in one minute get different x', () {
    expect(dayHour(DateTime(2026, 10, 6, 13, 30)), 13.5);
    expect(dayHour(DateTime(2026, 10, 6, 0, 0, 36)), closeTo(0.01, 1e-9));
  });

  test('daySpots keeps every reading of the same minute apart and in order', () {
    final readings = [
      for (var s = 0; s < 6; s++) _reading(s, DateTime(2026, 10, 6, 0, 1, s * 10), 26 + s * 0.1),
    ];

    final xs = daySpots(readings).map((spot) => spot.x).toList();

    expect(xs.toSet(), hasLength(readings.length));
    expect([...xs]..sort(), xs);
  });

  test('formatDayHour shows HH:mm, rounding to the nearest minute', () {
    expect(formatDayHour(0), '00:00');
    expect(formatDayHour(13.5), '13:30');
    expect(formatDayHour(0.0167), '00:01');
    expect(formatDayHour(23.999), '00:00');
  });

  testWidgets('a dense burst of readings inside one minute renders', (tester) async {
    final readings = [
      for (var s = 0; s < 40; s++)
        _reading(s, DateTime(2026, 10, 6, 0, 1, s), 26.5 + (s % 3) * 0.1),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            child: SensorChart(
              title: 'Temperature',
              unit: '°C',
              color: Colors.red,
              dataPoints: daySpots(readings),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Temperature (°C)'), findsOneWidget);
  });
}
