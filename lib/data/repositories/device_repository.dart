import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/device_action_history_item.dart';
import 'package:gp1/data/models/dto/device_command_result.dart';
import 'package:gp1/data/models/dto/device_history_query.dart';
import 'package:gp1/data/models/dto/page_response.dart';

/// The ESP32's controllable devices (LEDs), stored in the backend `devices` table.
abstract interface class DeviceRepository {
  /// `GET /api/devices`, ordered by id.
  Future<Result<List<Device>>> getDevices();

  /// `POST /api/devices/{deviceId}/command`. Any response carrying a
  /// [DeviceCommandResult] body, including the HTTP 504 timeout response, is a `Success`; check
  /// its `status`.
  Future<Result<DeviceCommandResult>> sendCommand(int deviceId, DeviceCommand command);

  /// `GET /api/devices/control-history`
  Future<Result<PageResponse<DeviceActionHistoryItem>>> getControlHistory(DeviceHistoryQuery query);
}
