import 'package:gp1/data/models/sensor.dart';

const mockSensors = <Sensor>[
  Sensor(id: 1, name: 'Temperature', type: SensorType.temperature, unit: '°C'),
  Sensor(id: 2, name: 'Humidity', type: SensorType.humidity, unit: '%'),
  Sensor(id: 3, name: 'Light', type: SensorType.light, unit: 'lux'),
];

Sensor mockSensorOf(SensorType type) => mockSensors.firstWhere((s) => s.type == type);

int mockSensorIdOf(SensorType type) => mockSensorOf(type).id;
