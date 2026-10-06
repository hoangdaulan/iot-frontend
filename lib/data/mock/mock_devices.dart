import 'package:gp1/data/models/device.dart';

/// The ESP32's three LEDs, matching the backend seed.
const mockDevice = Device(id: 1, name: 'LED 1', type: 'LED', status: DeviceStatus.off);

const _mockLeds = [
  mockDevice,
  Device(id: 2, name: 'LED 2', type: 'LED', status: DeviceStatus.off),
  Device(id: 3, name: 'LED 3', type: 'LED', status: DeviceStatus.off),
];

/// Device states shared by the mock repositories for the app session, so a Refresh reflects the
/// last command like the real backend does.
final mockDeviceStatuses = {for (final d in _mockLeds) d.id: d.status};

/// The mock devices with their current session status.
List<Device> currentMockDevices() => [
  for (final d in _mockLeds) d.copyWith(status: mockDeviceStatuses[d.id] ?? d.status),
];

void resetMockDevices() {
  for (final d in _mockLeds) {
    mockDeviceStatuses[d.id] = d.status;
  }
}
