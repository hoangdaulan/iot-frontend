import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/mock/mock_device_actions.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/device_action_history_item.dart';
import 'package:gp1/data/models/dto/device_command_result.dart';
import 'package:gp1/data/models/dto/device_history_query.dart';
import 'package:gp1/data/models/dto/page_response.dart';
import 'package:gp1/data/repositories/device_repository.dart';
import 'package:gp1/data/repositories/mock/mock_device_repository.dart';
import 'package:gp1/data/repositories/mock_history_device_repository.dart';

/// Stands in for the backend and fails if the control history is read from it.
class _FakeApi implements DeviceRepository {
  var sent = <(int, DeviceCommand)>[];
  Result<DeviceCommandResult>? commandResult;

  @override
  Future<Result<List<Device>>> getDevices() async =>
      const Success([Device(id: 7, name: 'Real LED', type: 'LED', status: DeviceStatus.off)]);

  @override
  Future<Result<DeviceCommandResult>> sendCommand(int deviceId, DeviceCommand command) async {
    sent.add((deviceId, command));
    return commandResult!;
  }

  @override
  Future<Result<PageResponse<DeviceActionHistoryItem>>> getControlHistory(
    DeviceHistoryQuery query,
  ) => throw StateError('control history must not come from the backend');
}

void main() {
  late _FakeApi api;
  late MockHistoryDeviceRepository repository;

  setUp(() {
    api = _FakeApi();
    repository = MockHistoryDeviceRepository(api, MockDeviceRepository());
  });

  test('devices come from the backend and the history from the mock data', () async {
    expect((await repository.getDevices()).dataOrNull?.single.name, 'Real LED');

    final page = (await repository.getControlHistory(
      const DeviceHistoryQuery(size: 5),
    )).dataOrNull!;
    expect(page.content, hasLength(5));
    expect(page.totalElements, greaterThanOrEqualTo(200));
  });

  test('the history is stable between calls, so paging is consistent', () async {
    const query = DeviceHistoryQuery(page: 1, size: 10);
    final first = (await repository.getControlHistory(query)).dataOrNull!.content;
    final second = (await repository.getControlHistory(query)).dataOrNull!.content;

    expect(second, first);
  });

  test('a command sent to the backend is added to the top of the mock history', () async {
    api.commandResult = const Success(
      DeviceCommandResult(
        deviceId: 2,
        command: DeviceCommand.on,
        status: DeviceActionResult.success,
        message: 'Device turned on successfully',
      ),
    );

    await repository.sendCommand(2, DeviceCommand.on);

    expect(api.sent, [(2, DeviceCommand.on)]);
    final newest = (await repository.getControlHistory(
      const DeviceHistoryQuery(size: 1),
    )).dataOrNull!.content.single;
    expect(newest.deviceId, 2);
    expect(newest.deviceName, 'LED 2');
    expect(newest.action, DeviceActionType.turnOn);
    expect(newest.result, DeviceActionResult.success);
    expect(newest.status, DeviceStatus.on);
  });

  test('a request that fails is not recorded', () async {
    final before = mockControlHistory.length;
    api.commandResult = const Failure(code: 403, message: 'You do not have permission');

    await repository.sendCommand(1, DeviceCommand.off);

    expect(mockControlHistory.length, before);
  });
}
