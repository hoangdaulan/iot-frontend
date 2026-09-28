enum DeviceAction {
  on('ON'),
  off('OFF');

  final String label;
  const DeviceAction(this.label);
}

enum ActionStatus {
  success('Success'),
  failed('Failed');

  final String label;
  const ActionStatus(this.label);
}

class ControlAction {
  final String id;
  final String deviceType;
  final DeviceAction action;
  final ActionStatus status;
  final DateTime timestamp;

  const ControlAction({
    required this.id,
    required this.deviceType,
    required this.action,
    required this.status,
    required this.timestamp,
  });
}
