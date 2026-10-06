/// What the sensor history search text is matched against. Sent as the `filter` parameter of
/// `GET /api/sensor-data/history`.
enum SensorSearchField {
  all('all', 'All', 'Sensor, value or time'),
  sensor('sensor', 'Sensor', 'Sensor ID or name'),
  temperature('temperature', 'Temperature', 'Value, e.g. 28 for 28.0 - 28.99'),
  humidity('humidity', 'Humidity', 'Value, e.g. 65'),
  light('light', 'Light', 'Value, e.g. 420'),
  time('time', 'Time', 'yyyy/MM/dd HH:mm:ss, e.g. 2026/10/06 11');

  const SensorSearchField(this.wireValue, this.label, this.hint);

  final String wireValue;
  final String label;
  final String hint;
}
