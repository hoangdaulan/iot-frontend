import 'package:gp1/data/models/device_action.dart';
import 'package:json_annotation/json_annotation.dart';

part 'device_command_request.g.dart';

/// Body of `POST /api/devices/{id}/command`.
@JsonSerializable(createFactory: false)
class DeviceCommandRequest {
  const DeviceCommandRequest({required this.command});

  final DeviceCommand command;

  Map<String, dynamic> toJson() => _$DeviceCommandRequestToJson(this);
}
