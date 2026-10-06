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

/// Devices and commands go to the backend, but the control history is served from the mock data
/// instead of the database. A command that reaches the backend is also added to that mock history,
/// so it shows up on the Control History screen.
class MockHistoryDeviceRepository implements DeviceRepository {
  MockHistoryDeviceRepository(this._api, this._mock);

  final DeviceRepository _api;
  final MockDeviceRepository _mock;

  @override
  Future<Result<List<Device>>> getDevices() => _api.getDevices();

  @override
  Future<Result<DeviceCommandResult>> sendCommand(int deviceId, DeviceCommand command) async {
    final result = await _api.sendCommand(deviceId, command);
    if (result case Success(data: final commandResult)) recordMockAction(commandResult);
    return result;
  }

  @override
  Future<Result<PageResponse<DeviceActionHistoryItem>>> getControlHistory(
    DeviceHistoryQuery query,
  ) => _mock.getControlHistory(query);
}
