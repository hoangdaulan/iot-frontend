import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/device_action_history_item.dart';
import 'package:gp1/data/models/dto/device_command_result.dart';
import 'package:gp1/data/models/dto/device_history_query.dart';
import 'package:gp1/data/models/dto/page_response.dart';
import 'package:gp1/data/repositories/device_repository.dart';

/// A device repository for tests: three LEDs whose status follows the commands sent, and a
/// control history of 200 actions spread over them. The history applies the device, action and
/// result filters and the paging of the query, and every query is recorded. The time search is
/// the backend's job and is tested there.
class FakeDeviceRepository implements DeviceRepository {
  FakeDeviceRepository({this.commandResult});

  /// The answer to every command; by default a command succeeds and sets the LED's status.
  Result<DeviceCommandResult>? commandResult;

  final statuses = {1: DeviceStatus.off, 2: DeviceStatus.off, 3: DeviceStatus.off};
  final historyQueries = <DeviceHistoryQuery>[];
  var deviceCalls = 0;

  List<Device> get devices => [
    for (final entry in statuses.entries)
      Device(id: entry.key, name: 'LED ${entry.key}', type: 'LED', status: entry.value),
  ];

  late final List<DeviceActionHistoryItem> _history = [
    for (var i = 0; i < 200; i++)
      DeviceActionHistoryItem(
        id: i,
        deviceId: i % 3 + 1,
        deviceName: 'LED ${i % 3 + 1}',
        action: i.isEven ? DeviceActionType.turnOn : DeviceActionType.turnOff,
        result: i % 7 == 0 ? DeviceActionResult.failed : DeviceActionResult.success,
        timestamp: DateTime(2026, 10, 6, 12).subtract(Duration(minutes: i * 47)),
      ),
  ];

  @override
  Future<Result<List<Device>>> getDevices() async {
    deviceCalls++;
    return Success(devices);
  }

  @override
  Future<Result<DeviceCommandResult>> sendCommand(int deviceId, DeviceCommand command) async {
    final scripted = commandResult;
    if (scripted != null) return scripted;

    statuses[deviceId] = command.resultingStatus;
    return Success(
      DeviceCommandResult(
        deviceId: deviceId,
        command: command,
        status: DeviceActionResult.success,
        message: 'Device turned ${command.label.toLowerCase()} successfully',
      ),
    );
  }

  @override
  Future<Result<PageResponse<DeviceActionHistoryItem>>> getControlHistory(
    DeviceHistoryQuery query,
  ) async {
    historyQueries.add(query);

    final items = _history
        .where((a) => query.deviceId == null || a.deviceId == query.deviceId)
        .where((a) => query.action == null || a.action == query.action)
        .where((a) => query.result == null || a.result == query.result)
        .toList();
    final page = query.page ?? 0;
    final size = query.size ?? 20;
    return Success(
      PageResponse(
        content: items.skip(page * size).take(size).toList(),
        page: page,
        size: size,
        totalElements: items.length,
        totalPages: (items.length / size).ceil(),
      ),
    );
  }
}
