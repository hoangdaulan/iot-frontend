import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/mock/mock_device_actions.dart';
import 'package:gp1/data/mock/mock_devices.dart';
import 'package:gp1/data/mock/mock_search.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/device_action_history_item.dart';
import 'package:gp1/data/models/dto/device_command_result.dart';
import 'package:gp1/data/models/dto/device_history_query.dart';
import 'package:gp1/data/models/dto/page_response.dart';
import 'package:gp1/data/repositories/device_repository.dart';

/// Commands always succeed and update [mockDeviceStatuses]; each one is added to the mock control
/// history.
class MockDeviceRepository implements DeviceRepository {
  @override
  Future<Result<List<Device>>> getDevices() async => Success(currentMockDevices());

  @override
  Future<Result<DeviceCommandResult>> sendCommand(int deviceId, DeviceCommand command) async {
    mockDeviceStatuses[deviceId] = command.resultingStatus;
    final result = DeviceCommandResult(
      deviceId: deviceId,
      command: command,
      status: DeviceActionResult.success,
      message: 'Device turned ${command == DeviceCommand.on ? 'on' : 'off'} successfully',
    );
    recordMockAction(result);
    return Success(result);
  }

  @override
  Future<Result<PageResponse<DeviceActionHistoryItem>>> getControlHistory(
    DeviceHistoryQuery query,
  ) async {
    final from = query.from;
    final to = query.to;
    final text = (query.query ?? '').trim();
    final timeRange = text.isEmpty ? null : mockTimePrefixRange(text);
    // Like the backend, a query that is not a time is rejected instead of matching nothing.
    if (text.isNotEmpty && timeRange == null) {
      return const Failure(code: 400, message: 'Invalid query parameters: q must be a time');
    }
    final items = mockControlHistory
        .where((a) => from == null || !a.timestamp.isBefore(from))
        .where((a) => to == null || !a.timestamp.isAfter(to))
        .where((a) => query.deviceId == null || a.deviceId == query.deviceId)
        .where((a) => query.action == null || a.action == query.action)
        .where((a) => query.result == null || a.result == query.result)
        .where(
          (a) =>
              timeRange == null ||
              (!a.timestamp.isBefore(timeRange.$1) && a.timestamp.isBefore(timeRange.$2)),
        )
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
