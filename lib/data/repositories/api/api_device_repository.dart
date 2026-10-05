import 'package:dio/dio.dart';
import 'package:gp1/app/constants/app_constants.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/device_action_history_item.dart';
import 'package:gp1/data/models/dto/device_command_request.dart';
import 'package:gp1/data/models/dto/device_command_result.dart';
import 'package:gp1/data/models/dto/device_history_query.dart';
import 'package:gp1/data/models/dto/page_response.dart';
import 'package:gp1/data/remote/api_failure.dart';
import 'package:gp1/data/repositories/device_repository.dart';

class ApiDeviceRepository implements DeviceRepository {
  ApiDeviceRepository(this._dio);

  final Dio _dio;

  @override
  Future<Result<DeviceCommandResult>> sendCommand(DeviceCommand command) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/devices/${AppConstants.deviceId}/command',
        data: DeviceCommandRequest(command: command).toJson(),
      );
      return Success(DeviceCommandResult.fromJson(res.data!));
    } on DioException catch (e) {
      // A hardware timeout is answered with HTTP 504 and a DeviceCommandResult body.
      final data = e.response?.data;
      if (data is Map<String, dynamic> &&
          data.containsKey('deviceId') &&
          data.containsKey('status')) {
        return Success(DeviceCommandResult.fromJson(data));
      }
      return failureFromDio(e);
    }
  }

  @override
  Future<Result<PageResponse<DeviceActionHistoryItem>>> getControlHistory(
    DeviceHistoryQuery query,
  ) => guardRequest(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/devices/control-history',
      queryParameters: query.toQueryParameters(),
    );
    return PageResponse.fromJson(
      res.data!,
      (json) => DeviceActionHistoryItem.fromJson(json as Map<String, dynamic>),
    );
  });
}
