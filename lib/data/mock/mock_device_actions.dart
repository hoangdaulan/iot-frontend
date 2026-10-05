import 'package:gp1/data/mock/mock_devices.dart';
import 'package:gp1/data/mock/mock_random.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/device_action_history_item.dart';

// ── Control History (spanning Sept 2025 to Sept 2026) ──
List<DeviceActionHistoryItem> generateControlHistory({int count = 200}) {
  final start = DateTime(2025, 9, 1, 0, 0, 0);
  final end = DateTime(2026, 9, 30, 23, 59, 59);
  final totalSeconds = end.difference(start).inSeconds;
  final actions = <DeviceActionHistoryItem>[];

  final step = totalSeconds / count;

  for (var i = 0; i < count; i++) {
    final jitter = mockRandom.nextInt((step * 0.8).toInt().clamp(1, 10000));
    final secondsOffset = (i * step + jitter).toInt();
    final timestamp = start.add(Duration(seconds: secondsOffset.clamp(0, totalSeconds)));
    final action = mockRandom.nextBool() ? DeviceActionType.turnOn : DeviceActionType.turnOff;
    final result = mockRandom.nextDouble() > 0.15
        ? DeviceActionResult.success
        : DeviceActionResult.failed;

    actions.add(
      DeviceActionHistoryItem(
        id: i,
        deviceId: mockDevice.id,
        deviceName: mockDevice.name,
        action: action,
        result: result,
        timestamp: timestamp,
        status: result == DeviceActionResult.success
            ? (action == DeviceActionType.turnOn ? DeviceStatus.on : DeviceStatus.off)
            : null,
      ),
    );
  }

  actions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return actions;
}
