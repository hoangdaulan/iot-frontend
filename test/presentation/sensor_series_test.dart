import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_reading.dart';
import 'package:gp1/presentation/sensors/models/sensor_series.dart';

SensorReading _reading(SensorType type, double value, int minute) => SensorReading(
  id: minute,
  sensorId: type.index + 1,
  type: type,
  value: value,
  timestamp: DateTime(2026, 9, 11, 12, minute),
);

void main() {
  test('group splits by type and orders each series oldest first', () {
    final series = SensorSeries.group([
      _reading(SensorType.temperature, 29.0, 20),
      _reading(SensorType.humidity, 60.0, 0),
      _reading(SensorType.temperature, 28.0, 10),
    ]);

    expect(series.keys, SensorType.values);
    expect(series.of(SensorType.temperature).readings.map((r) => r.value), [28.0, 29.0]);
    expect(series.of(SensorType.light).readings, isEmpty);
  });

  test('latestValue and trend come from the last two readings', () {
    final series = SensorSeries.group([
      _reading(SensorType.light, 500, 0),
      _reading(SensorType.light, 520.3, 10),
      _reading(SensorType.light, 512.2, 20),
    ]).of(SensorType.light);

    expect(series.latestValue, 512.2);
    expect(series.trend, -8.1);
  });

  test('empty and single-reading series fall back to zero', () {
    expect(const SensorSeries(type: SensorType.humidity).latestValue, 0.0);
    expect(
      SensorSeries.group([_reading(SensorType.humidity, 61, 0)]).of(SensorType.humidity).trend,
      0.0,
    );
  });
}
