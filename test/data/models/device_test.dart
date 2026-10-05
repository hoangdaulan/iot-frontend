import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/device_action_history_item.dart';
import 'package:gp1/data/models/dto/device_command_request.dart';
import 'package:gp1/data/models/dto/device_command_result.dart';
import 'package:gp1/data/models/dto/device_history_query.dart';
import 'package:gp1/data/models/dto/page_response.dart';

void main() {
  group('Device.fromJson', () {
    test('parses an LED device with ON/OFF status and local timestamps', () {
      final device = Device.fromJson({
        'id': 1,
        'name': 'Đèn phòng khách',
        'type': 'LED',
        'status': 'ON',
        'mqttTopic': 'home/led/1',
        'createdAt': '2026-09-01T08:00:00Z',
        'updatedAt': '2026-09-02T08:00:00Z',
      });

      expect(device.type, 'LED');
      expect(device.status, DeviceStatus.on);
      expect(device.isOn, isTrue);
      expect(device.mqttTopic, 'home/led/1');
      expect(device.createdAt, DateTime.utc(2026, 9, 1, 8).toLocal());
      expect(Device.fromJson({...device.toJson(), 'status': 'OFF'}).status, DeviceStatus.off);
    });

    test('tolerates missing optional fields and unknown status', () {
      final device = Device.fromJson({'id': 2, 'name': 'Fan', 'type': 'FAN', 'status': 'BROKEN'});

      expect(device.status, DeviceStatus.unknown);
      expect(device.isOn, isFalse);
      expect(device.mqttTopic, isNull);
      expect(device.createdAt, isNull);
    });

    test('serializes status with the backend wire values', () {
      const device = Device(id: 1, name: 'LED', type: 'LED', status: DeviceStatus.on);

      expect(device.toJson()['status'], 'ON');
      expect(device.copyWith(status: DeviceStatus.off).toJson()['status'], 'OFF');
    });

    test('round-trips through toJson', () {
      final device = Device(
        id: 1,
        name: 'LED',
        type: 'LED',
        status: DeviceStatus.off,
        createdAt: DateTime(2026, 1, 2, 3, 4, 5),
      );

      expect(Device.fromJson(device.toJson()), device);
    });
  });

  group('DeviceAction.fromJson', () {
    test('parses TURN_ON / TURN_OFF actions', () {
      Map<String, dynamic> json(String action) => {
        'id': 10,
        'deviceId': 1,
        'userId': 7,
        'action': action,
        'result': 'SUCCESS',
        'timestamp': '2026-09-11T15:12:11Z',
      };

      expect(DeviceAction.fromJson(json('TURN_ON')).action, DeviceActionType.turnOn);
      expect(DeviceAction.fromJson(json('TURN_OFF')).action, DeviceActionType.turnOff);
      expect(DeviceAction.fromJson(json('TURN_ON')).userId, 7);
    });

    test('parses SUCCESS / FAILED / TIMEOUT / PENDING results', () {
      DeviceActionResult parse(String result) => DeviceAction.fromJson({
        'id': 10,
        'deviceId': 1,
        'action': 'TURN_ON',
        'result': result,
        'timestamp': '2026-09-11T15:12:11Z',
      }).result;

      expect(parse('SUCCESS'), DeviceActionResult.success);
      expect(parse('FAILED'), DeviceActionResult.failed);
      expect(parse('TIMEOUT'), DeviceActionResult.timeout);
      expect(parse('PENDING'), DeviceActionResult.pending);
      expect(parse('CANCELLED'), DeviceActionResult.unknown);
    });

    test('rejects an unsupported action', () {
      expect(
        () => DeviceAction.fromJson({
          'id': 10,
          'deviceId': 1,
          'action': 'TOGGLE',
          'result': 'SUCCESS',
          'timestamp': '2026-09-11T15:12:11Z',
        }),
        throwsArgumentError,
      );
    });

    test('round-trips with the backend wire values', () {
      final action = DeviceAction(
        id: 1,
        deviceId: 2,
        action: DeviceActionType.turnOff,
        result: DeviceActionResult.timeout,
        timestamp: DateTime(2026, 9, 11, 15),
      );
      final json = action.toJson();

      expect(json['action'], 'TURN_OFF');
      expect(json['result'], 'TIMEOUT');
      expect(DeviceAction.fromJson(json), action);
    });
  });

  group('device command', () {
    test('DeviceCommandRequest sends {"command": "ON" | "OFF"}', () {
      expect(const DeviceCommandRequest(command: DeviceCommand.on).toJson(), {'command': 'ON'});
      expect(const DeviceCommandRequest(command: DeviceCommand.off).toJson(), {'command': 'OFF'});
    });

    test('DeviceCommandResult parses a successful response', () {
      final result = DeviceCommandResult.fromJson({
        'deviceId': 1,
        'command': 'ON',
        'status': 'SUCCESS',
        'message': 'Device turned on successfully',
      });

      expect(result.deviceId, 1);
      expect(result.command, DeviceCommand.on);
      expect(result.status, DeviceActionResult.success);
      expect(result.isSuccess, isTrue);
      expect(result.message, 'Device turned on successfully');
    });

    test('DeviceCommandResult parses failed and timed-out responses', () {
      final timeout = DeviceCommandResult.fromJson({
        'deviceId': 1,
        'command': 'OFF',
        'status': 'TIMEOUT',
        'message': 'Device did not respond in time',
      });
      final failed = DeviceCommandResult.fromJson({
        'deviceId': 1,
        'command': 'OFF',
        'status': 'FAILED',
      });

      expect(timeout.status, DeviceActionResult.timeout);
      expect(timeout.isSuccess, isFalse);
      expect(failed.status, DeviceActionResult.failed);
      expect(failed.message, isNull);
    });

    test('DeviceCommandResult round-trips through toJson', () {
      const result = DeviceCommandResult(
        deviceId: 1,
        command: DeviceCommand.off,
        status: DeviceActionResult.failed,
        message: 'LED did not switch',
      );

      expect(result.toJson(), {
        'deviceId': 1,
        'command': 'OFF',
        'status': 'FAILED',
        'message': 'LED did not switch',
      });
      expect(DeviceCommandResult.fromJson(result.toJson()), result);
    });

    test('DeviceCommand maps to the device status it produces', () {
      expect(DeviceCommand.on.resultingStatus, DeviceStatus.on);
      expect(DeviceCommand.off.resultingStatus, DeviceStatus.off);
    });
  });

  group('control history', () {
    test('parses the paged response documented in the report', () {
      final page = PageResponse<DeviceActionHistoryItem>.fromJson({
        'content': [
          {
            'id': 101,
            'deviceId': 1,
            'deviceName': 'Đèn phòng khách',
            'action': 'TURN_ON',
            'status': 'ON',
            'result': 'SUCCESS',
            'timestamp': '2026-08-19T14:30:05',
            'message': 'Device turned on successfully',
          },
        ],
        'page': 0,
        'size': 20,
        'totalElements': 1,
        'totalPages': 1,
      }, (json) => DeviceActionHistoryItem.fromJson(json as Map<String, dynamic>));

      final item = page.content.single;
      expect(page.page, 0);
      expect(page.size, 20);
      expect(page.totalElements, 1);
      expect(page.totalPages, 1);
      expect(item.deviceName, 'Đèn phòng khách');
      expect(item.action, DeviceActionType.turnOn);
      expect(item.status, DeviceStatus.on);
      expect(item.result, DeviceActionResult.success);
      expect(item.timestamp, DateTime(2026, 8, 19, 14, 30, 5));
      expect(item.message, 'Device turned on successfully');
    });

    test('history item tolerates a missing status and message', () {
      final item = DeviceActionHistoryItem.fromJson({
        'id': 1,
        'deviceId': 1,
        'deviceName': 'LED',
        'action': 'TURN_OFF',
        'result': 'TIMEOUT',
        'timestamp': '2026-08-19T14:30:05',
      });

      expect(item.status, isNull);
      expect(item.message, isNull);
      expect(item.result, DeviceActionResult.timeout);
      expect(DeviceActionHistoryItem.fromJson(item.toJson()), item);
    });

    test('DeviceHistoryQuery sends only the parameters that are set', () {
      expect(const DeviceHistoryQuery().toQueryParameters(), isEmpty);
      expect(
        DeviceHistoryQuery(
          from: DateTime.utc(2026, 8, 1),
          to: DateTime.utc(2026, 8, 31),
          page: 0,
          size: 20,
        ).toQueryParameters(),
        {
          'from': '2026-08-01T00:00:00.000Z',
          'to': '2026-08-31T00:00:00.000Z',
          'page': '0',
          'size': '20',
        },
      );
    });
  });
}
