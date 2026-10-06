import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/dto/latest_sensor_data_response.dart';
import 'package:gp1/data/models/dto/sensor_history_query.dart';
import 'package:gp1/data/models/dto/sensor_history_response.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_search_field.dart';
import 'package:gp1/data/models/sensor_data.dart';

void main() {
  group('Sensor.fromJson', () {
    test('parses temperature / humidity / light types', () {
      SensorType parse(String type) =>
          Sensor.fromJson({'id': 1, 'name': 'S', 'type': type, 'unit': 'u'}).type;

      expect(parse('temperature'), SensorType.temperature);
      expect(parse('humidity'), SensorType.humidity);
      expect(parse('light'), SensorType.light);
    });

    test('keeps the backend status as a free-form string', () {
      final sensor = Sensor.fromJson({
        'id': 1,
        'name': 'DHT22',
        'type': 'temperature',
        'unit': '°C',
        'status': 'CALIBRATING',
        'mqttTopic': 'home/temp',
        'createdAt': '2026-09-01T08:00:00Z',
      });

      expect(sensor.status, 'CALIBRATING');
      expect(sensor.unit, '°C');
      expect(sensor.updatedAt, isNull);
      expect(
        Sensor.fromJson({'id': 1, 'name': 'S', 'type': 'light', 'unit': 'lux'}).status,
        isNull,
      );
    });

    test('rejects an unsupported sensor type', () {
      expect(
        () => Sensor.fromJson({'id': 1, 'name': 'CO2', 'type': 'co2', 'unit': 'ppm'}),
        throwsArgumentError,
      );
    });
  });

  group('SensorData.fromJson', () {
    test('accepts integer and double values', () {
      final fromInt = SensorData.fromJson({
        'id': 1,
        'sensorId': 2,
        'value': 28,
        'timestamp': '2026-09-11T15:12:11Z',
      });
      final fromDouble = SensorData.fromJson({
        'id': 1,
        'sensorId': 2,
        'value': 28.7,
        'timestamp': '2026-09-11T15:12:11Z',
      });

      expect(fromInt.value, 28.0);
      expect(fromInt.value, isA<double>());
      expect(fromDouble.value, 28.7);
    });

    test('parses timestamps with and without a timezone', () {
      final utc = SensorData.fromJson({
        'id': 1,
        'sensorId': 2,
        'value': 1,
        'timestamp': '2026-09-11T15:12:11Z',
      });
      final local = SensorData.fromJson({
        'id': 1,
        'sensorId': 2,
        'value': 1,
        'timestamp': '2026-09-11T15:12:11',
      });

      expect(utc.timestamp, DateTime.utc(2026, 9, 11, 15, 12, 11).toLocal());
      expect(local.timestamp, DateTime(2026, 9, 11, 15, 12, 11));
    });

    test('round-trips through toJson', () {
      final data = SensorData(id: 1, sensorId: 2, value: 61.5, timestamp: DateTime(2026, 9, 11));

      expect(SensorData.fromJson(data.toJson()), data);
    });
  });

  group('SensorHistoryResponse', () {
    test('parses the grouped response (report shape, 0-based paging + totals)', () {
      final response = SensorHistoryResponse.fromJson({
        'data': {
          'temperature': [
            {'id': 101, 'value': 26.5, 'unit': '°C', 'timestamp': '2026-08-14T14:00:05'},
          ],
          'humidity': [
            {'id': 102, 'value': 65.2, 'unit': '%', 'timestamp': '2026-08-14T14:00:05'},
          ],
          'light': [
            {'id': 103, 'value': 420, 'unit': 'lux', 'timestamp': '2026-08-14T14:00:05'},
          ],
        },
        'page': 0,
        'pageSize': 20,
        'totalElements': 3,
        'totalPages': 1,
      });

      expect(response.page, 0);
      expect(response.pageSize, 20);
      expect(response.totalElements, 3);
      expect(response.totalPages, 1);
      expect(response.data[SensorType.temperature]!.single.unit, '°C');

      final readings = response.toReadings();
      expect(readings.map((r) => (r.id, r.type, r.value)), [
        (101, SensorType.temperature, 26.5),
        (102, SensorType.humidity, 65.2),
        (103, SensorType.light, 420.0),
      ]);
      expect(readings.first.timestamp, DateTime(2026, 8, 14, 14, 0, 5));
      expect(readings.first.sensorId, isNull);
    });

    test('orders readings newest first and tolerates missing types', () {
      final readings = SensorHistoryResponse.fromJson({
        'data': {
          'light': [
            {'id': 1, 'value': 10, 'timestamp': '2026-08-14T10:00:00'},
            {'id': 2, 'value': 20, 'timestamp': '2026-08-14T12:00:00'},
          ],
        },
      }).toReadings();

      expect(readings.map((r) => r.id), [2, 1]);
    });

    test('rejects an unsupported sensor type key', () {
      expect(
        () => SensorHistoryResponse.fromJson({
          'data': {'co2': <Object>[]},
        }),
        throwsArgumentError,
      );
    });
  });

  test('LatestSensorDataResponse converts each type to one reading and reads the LED status', () {
    final latest = LatestSensorDataResponse.fromJson({
      'deviceStatus': 'ON',
      'data': {
        'temperature': {'id': 201, 'value': 27, 'unit': '°C', 'timestamp': '2026-08-14T14:05:00'},
        'humidity': {'id': 202, 'value': 63.4, 'unit': '%', 'timestamp': '2026-08-14T14:05:00'},
      },
    });

    expect(latest.deviceStatus, DeviceStatus.on);
    expect(latest.toReadings().map((r) => (r.type, r.value)), [
      (SensorType.temperature, 27.0),
      (SensorType.humidity, 63.4),
    ]);
    expect(LatestSensorDataResponse.fromJson(latest.toJson()), latest);
  });

  test('SensorHistoryQuery encodes type, timeRange, value and paging', () {
    expect(const SensorHistoryQuery().toQueryParameters(), isEmpty);
    expect(
      SensorHistoryQuery(
        type: SensorType.humidity,
        from: DateTime.utc(2026, 8, 1),
        to: DateTime.utc(2026, 8, 2),
        value: 65.2,
        page: 1,
        size: 20,
      ).toQueryParameters(),
      {
        'type': 'humidity',
        'timeRange': '2026-08-01T00:00:00.000Z/2026-08-02T00:00:00.000Z',
        'value': '65.2',
        'page': '1',
        'size': '20',
      },
    );
    expect(
      SensorHistoryQuery(from: DateTime.utc(2026, 8, 1)).toQueryParameters()['timeRange'],
      '2026-08-01T00:00:00.000Z/..',
    );
  });

  group('SensorHistoryQuery search', () {
    test('sends filter and q, and the UTC offset only for a time search', () {
      expect(
        const SensorHistoryQuery(
          searchField: SensorSearchField.time,
          searchQuery: ' 2026/10/06 11 ',
          utcOffsetMinutes: 420,
        ).toQueryParameters(),
        {'filter': 'time', 'q': '2026/10/06 11', 'utcOffset': '420'},
      );
      expect(
        const SensorHistoryQuery(
          searchField: SensorSearchField.temperature,
          searchQuery: '28.5',
          utcOffsetMinutes: 420,
        ).toQueryParameters(),
        {'filter': 'temperature', 'q': '28.5'},
      );
    });

    test('All sends the query with the UTC offset, an empty query sends nothing', () {
      expect(
        const SensorHistoryQuery(
          searchField: SensorSearchField.all,
          searchQuery: 'led',
          utcOffsetMinutes: 420,
        ).toQueryParameters(),
        {'q': 'led', 'utcOffset': '420'},
      );
      expect(
        const SensorHistoryQuery(
          searchField: SensorSearchField.all,
          searchQuery: ' ',
        ).toQueryParameters(),
        isEmpty,
      );
      expect(
        const SensorHistoryQuery(
          searchField: SensorSearchField.sensor,
          searchQuery: '  ',
        ).toQueryParameters(),
        {'filter': 'sensor'},
      );
    });
  });
}
