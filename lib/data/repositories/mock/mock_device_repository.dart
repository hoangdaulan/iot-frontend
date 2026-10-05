import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/mock/mock_device_actions.dart';
import 'package:gp1/data/mock/mock_devices.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/device_action_history_item.dart';
import 'package:gp1/data/models/dto/device_command_result.dart';
import 'package:gp1/data/models/dto/device_history_query.dart';
import 'package:gp1/data/models/dto/page_response.dart';
import 'package:gp1/data/repositories/device_repository.dart';

/// Commands always succeed and update [mockLedStatus]; they are not appended to the generated
/// control history.
class MockDeviceRepository implements DeviceRepository {
  @override
  Future<Result<DeviceCommandResult>> sendCommand(DeviceCommand command) async {
    mockLedStatus = command.resultingStatus;
    return Success(
      DeviceCommandResult(
        deviceId: mockDevice.id,
        command: command,
        status: DeviceActionResult.success,
        message: 'Device turned ${command == DeviceCommand.on ? 'on' : 'off'} successfully',
      ),
    );
  }

  @override
  Future<Result<PageResponse<DeviceActionHistoryItem>>> getControlHistory(
    DeviceHistoryQuery query,
  ) async {
    final from = query.from;
    final to = query.to;
    final items = generateControlHistory(count: 200)
        .where((a) => from == null || !a.timestamp.isBefore(from))
        .where((a) => to == null || !a.timestamp.isAfter(to))
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
