import 'dart:math';

import 'package:gp1/data/mock/mock_random.dart';
import 'package:gp1/data/mock/mock_sensors.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_reading.dart';

// ── Sensor Readings for Today ──
List<SensorReading> generateTodaySensorReadings() {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final readings = <SensorReading>[];
  var id = 0;

  // Generate readings every 10 minutes up to current time
  for (var time = startOfDay; time.isBefore(now); time = time.add(const Duration(minutes: 10))) {
    final hour = time.hour;

    // Temperature: 22-35°C, peaks at noon
    final tempBase = 24.0 + 8.0 * sin((hour - 6) * pi / 12);
    readings.add(
      SensorReading(
        id: id++,
        sensorId: mockSensorIdOf(SensorType.temperature),
        type: SensorType.temperature,
        value: double.parse((tempBase + mockRandom.nextDouble() * 2 - 1).toStringAsFixed(1)),
        timestamp: time,
      ),
    );

    // Humidity: 40-80%, inverse of temperature
    final humBase = 65.0 - 15.0 * sin((hour - 6) * pi / 12);
    readings.add(
      SensorReading(
        id: id++,
        sensorId: mockSensorIdOf(SensorType.humidity),
        type: SensorType.humidity,
        value: double.parse((humBase + mockRandom.nextDouble() * 5 - 2.5).toStringAsFixed(1)),
        timestamp: time,
      ),
    );

    // Light: 0-1000 lux, peaks at midday
    final lightBase = hour >= 6 && hour <= 18
        ? 500.0 + 450.0 * sin((hour - 6) * pi / 12)
        : 5.0 + mockRandom.nextDouble() * 10;
    readings.add(
      SensorReading(
        id: id++,
        sensorId: mockSensorIdOf(SensorType.light),
        type: SensorType.light,
        value: double.parse(lightBase.toStringAsFixed(0)),
        timestamp: time,
      ),
    );
  }

  return readings;
}

// ── Sensor History (spanning Sept 2025 to Sept 2026) ──
List<SensorReading> generateSensorHistory({int count = 2016}) {
  final start = DateTime(2025, 9, 1, 0, 0, 0);
  final end = DateTime(2026, 9, 30, 23, 59, 59);
  final totalSeconds = end.difference(start).inSeconds;
  final readings = <SensorReading>[];

  final sensorTypes = [SensorType.temperature, SensorType.humidity, SensorType.light];
  var id = 1000;

  final samplesPerType = (count / sensorTypes.length).round();
  final step = totalSeconds / samplesPerType;

  for (var i = 0; i < samplesPerType; i++) {
    final jitter = mockRandom.nextInt((step * 0.8).toInt().clamp(1, 10000));
    final secondsOffset = (i * step + jitter).toInt();
    final time = start.add(Duration(seconds: secondsOffset.clamp(0, totalSeconds)));

    for (final type in sensorTypes) {
      final hour = time.hour;
      final month = time.month;

      double value;
      switch (type) {
        case SensorType.temperature:
          final seasonalEffect = 5.0 * sin((month - 4) * pi / 6);
          final dailyEffect = 6.0 * sin((hour - 6) * pi / 12);
          final baseTemp = 26.0 + seasonalEffect + dailyEffect;
          value = double.parse(
            (baseTemp + (mockRandom.nextDouble() * 3.0 - 1.5)).toStringAsFixed(1),
          );
        case SensorType.humidity:
          final seasonalEffect = 10.0 * cos((month - 8) * pi / 6);
          final dailyEffect = -10.0 * sin((hour - 6) * pi / 12);
          final baseHum = 65.0 + seasonalEffect + dailyEffect;
          value = double.parse(
            (baseHum + (mockRandom.nextDouble() * 6.0 - 3.0)).clamp(30.0, 99.0).toStringAsFixed(1),
          );
        case SensorType.light:
          final lightBase = (hour >= 6 && hour <= 18)
              ? 400.0 + 550.0 * sin((hour - 6) * pi / 12)
              : 2.0 + mockRandom.nextDouble() * 15;
          value = double.parse(
            (lightBase + (mockRandom.nextDouble() * 40 - 20)).clamp(0.0, 1200.0).toStringAsFixed(0),
          );
      }

      readings.add(
        SensorReading(
          id: id++,
          sensorId: mockSensorIdOf(type),
          type: type,
          value: value,
          timestamp: time,
        ),
      );
    }
  }

  readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return readings;
}

// ── Latest readings, as a device would report them on Refresh ──
var _nextLatestId = 100000;

List<SensorReading> generateLatestSensorReadings() {
  final now = DateTime.now();
  final hour = now.hour + now.minute / 60.0;
  final daylight = hour >= 6 && hour <= 18;

  SensorReading reading(SensorType type, double value) => SensorReading(
    id: _nextLatestId++,
    sensorId: mockSensorIdOf(type),
    type: type,
    value: value,
    timestamp: now,
  );

  return [
    reading(
      SensorType.temperature,
      double.parse(
        (24.0 + 8.0 * sin((hour - 6) * pi / 12) + mockRandom.nextDouble() * 2 - 1).toStringAsFixed(
          1,
        ),
      ),
    ),
    reading(
      SensorType.humidity,
      double.parse(
        (65.0 - 15.0 * sin((hour - 6) * pi / 12) + mockRandom.nextDouble() * 5 - 2.5)
            .toStringAsFixed(1),
      ),
    ),
    reading(
      SensorType.light,
      double.parse(
        (daylight ? 500.0 + 450.0 * sin((hour - 6) * pi / 12) : 5.0 + mockRandom.nextDouble() * 10)
            .toStringAsFixed(0),
      ),
    ),
  ];
}
