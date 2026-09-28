enum SensorType {
  temperature('Temperature', '°C'),
  humidity('Humidity', '%'),
  light('Light', 'lux');

  final String label;
  final String unit;

  const SensorType(this.label, this.unit);
}

class SensorReading {
  final String id;
  final SensorType type;
  final double value;
  final DateTime timestamp;

  const SensorReading({
    required this.id,
    required this.type,
    required this.value,
    required this.timestamp,
  });

  String get unit => type.unit;
}
