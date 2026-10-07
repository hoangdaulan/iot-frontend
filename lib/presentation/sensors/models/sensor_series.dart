import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_reading.dart';

/// Chronological readings of one sensor type, with the latest value that the stat cards display.
class SensorSeries {
  const SensorSeries({required this.type, this.readings = const []});

  final SensorType type;

  /// Ordered oldest → newest.
  final List<SensorReading> readings;

  /// Splits [readings] by type and sorts each series chronologically.
  static Map<SensorType, SensorSeries> group(Iterable<SensorReading> readings) {
    return {
      for (final type in SensorType.values)
        type: SensorSeries(
          type: type,
          readings: readings.where((r) => r.type == type).toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp)),
        ),
    };
  }

  double get latestValue => readings.isNotEmpty ? readings.last.value : 0.0;
}

extension SensorSeriesMapExtension on Map<SensorType, SensorSeries> {
  SensorSeries of(SensorType type) => this[type] ?? SensorSeries(type: type);
}
