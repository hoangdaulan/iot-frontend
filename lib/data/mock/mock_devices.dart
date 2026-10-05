import 'package:gp1/app/constants/app_constants.dart';
import 'package:gp1/data/models/device.dart';

/// The single ESP32, matching the backend seed.
const mockDevice = Device(
  id: AppConstants.deviceId,
  name: 'ESP32',
  type: 'LED',
  status: DeviceStatus.off,
);

/// LED state shared by the mock repositories for the app session, so a Refresh reflects the
/// last command like the real backend does.
var mockLedStatus = mockDevice.status;
