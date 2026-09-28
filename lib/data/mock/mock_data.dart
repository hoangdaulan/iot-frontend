import 'dart:math';

import 'package:gp1/data/models/control_action.dart';
import 'package:gp1/data/models/sensor_reading.dart';

class MockData {
  static final _random = Random(42);

  // ── Mock User Profile ──
  static const mockUsername = 'leo_nguyen';
  static const mockEmail = 'leo.nguyen@iot-project.com';
  static const mockPhone = '+84 912 345 678';
  static const mockRole = 'Admin';
  static const mockGithub = 'https://github.com/leo-nguyen';
  static const mockFigma = 'https://figma.com/@leo-nguyen';

  // ── Sensor Readings for Today ──
  static List<SensorReading> generateTodaySensorReadings() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final readings = <SensorReading>[];
    var id = 0;

    // Generate readings every 10 minutes up to current time
    for (var time = startOfDay;
        time.isBefore(now);
        time = time.add(const Duration(minutes: 10))) {
      final hour = time.hour;

      // Temperature: 22-35°C, peaks at noon
      final tempBase = 24.0 + 8.0 * sin((hour - 6) * pi / 12);
      readings.add(SensorReading(
        id: 'sr_${id++}',
        type: SensorType.temperature,
        value: double.parse((tempBase + _random.nextDouble() * 2 - 1).toStringAsFixed(1)),
        timestamp: time,
      ));

      // Humidity: 40-80%, inverse of temperature
      final humBase = 65.0 - 15.0 * sin((hour - 6) * pi / 12);
      readings.add(SensorReading(
        id: 'sr_${id++}',
        type: SensorType.humidity,
        value: double.parse((humBase + _random.nextDouble() * 5 - 2.5).toStringAsFixed(1)),
        timestamp: time,
      ));

      // Light: 0-1000 lux, peaks at midday
      final lightBase = hour >= 6 && hour <= 18
          ? 500.0 + 450.0 * sin((hour - 6) * pi / 12)
          : 5.0 + _random.nextDouble() * 10;
      readings.add(SensorReading(
        id: 'sr_${id++}',
        type: SensorType.light,
        value: double.parse(lightBase.toStringAsFixed(0)),
        timestamp: time,
      ));
    }

    return readings;
  }

  // ── Sensor History (spanning Sept 2025 to Sept 2026) ──
  static List<SensorReading> generateSensorHistory({int count = 2016}) {
    final start = DateTime(2025, 9, 1, 0, 0, 0);
    final end = DateTime(2026, 9, 30, 23, 59, 59);
    final totalSeconds = end.difference(start).inSeconds;
    final readings = <SensorReading>[];

    final sensorTypes = [SensorType.temperature, SensorType.humidity, SensorType.light];
    var id = 1000;

    final samplesPerType = (count / sensorTypes.length).round();
    final step = totalSeconds / samplesPerType;

    for (var i = 0; i < samplesPerType; i++) {
      final jitter = _random.nextInt((step * 0.8).toInt().clamp(1, 10000));
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
            value = double.parse((baseTemp + (_random.nextDouble() * 3.0 - 1.5)).toStringAsFixed(1));
          case SensorType.humidity:
            final seasonalEffect = 10.0 * cos((month - 8) * pi / 6);
            final dailyEffect = -10.0 * sin((hour - 6) * pi / 12);
            final baseHum = 65.0 + seasonalEffect + dailyEffect;
            value = double.parse((baseHum + (_random.nextDouble() * 6.0 - 3.0)).clamp(30.0, 99.0).toStringAsFixed(1));
          case SensorType.light:
            final lightBase = (hour >= 6 && hour <= 18)
                ? 400.0 + 550.0 * sin((hour - 6) * pi / 12)
                : 2.0 + _random.nextDouble() * 15;
            value = double.parse((lightBase + (_random.nextDouble() * 40 - 20)).clamp(0.0, 1200.0).toStringAsFixed(0));
        }

        readings.add(SensorReading(
          id: 'sr_${id++}',
          type: type,
          value: value,
          timestamp: time,
        ));
      }
    }

    readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return readings;
  }

  // ── Control History (spanning Sept 2025 to Sept 2026) ──
  static List<ControlAction> generateControlHistory({int count = 200}) {
    final start = DateTime(2025, 9, 1, 0, 0, 0);
    final end = DateTime(2026, 9, 30, 23, 59, 59);
    final totalSeconds = end.difference(start).inSeconds;
    final devices = ['Temperature Sensor', 'Humidity Sensor', 'Light Sensor'];
    final actions = <ControlAction>[];

    final step = totalSeconds / count;

    for (var i = 0; i < count; i++) {
      final jitter = _random.nextInt((step * 0.8).toInt().clamp(1, 10000));
      final secondsOffset = (i * step + jitter).toInt();
      final timestamp = start.add(Duration(seconds: secondsOffset.clamp(0, totalSeconds)));
      final device = devices[_random.nextInt(devices.length)];
      final action = _random.nextBool() ? DeviceAction.on : DeviceAction.off;
      final status = _random.nextDouble() > 0.15 ? ActionStatus.success : ActionStatus.failed;

      actions.add(ControlAction(
        id: 'ca_$i',
        deviceType: device,
        action: action,
        status: status,
        timestamp: timestamp,
      ));
    }

    actions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return actions;
  }
}

