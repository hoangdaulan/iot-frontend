import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/device_action_history_item.dart';
import 'package:gp1/data/models/dto/device_history_query.dart';
import 'package:gp1/data/models/dto/page_response.dart';
import 'package:gp1/data/repositories/mock/mock_device_repository.dart';
import 'package:gp1/presentation/control_history/cubit/control_history_cubit.dart';

/// Records the calls and delegates to the mock, which mirrors the backend filters.
class _RecordingDeviceRepository extends MockDeviceRepository {
  final queries = <DeviceHistoryQuery>[];
  var deviceCalls = 0;

  @override
  Future<Result<List<Device>>> getDevices() {
    deviceCalls++;
    return super.getDevices();
  }

  @override
  Future<Result<PageResponse<DeviceActionHistoryItem>>> getControlHistory(
    DeviceHistoryQuery query,
  ) {
    queries.add(query);
    return super.getControlHistory(query);
  }
}

void main() {
  late _RecordingDeviceRepository repository;
  late ControlHistoryCubit cubit;

  setUp(() {
    repository = _RecordingDeviceRepository();
    cubit = ControlHistoryCubit(repository);
  });

  test('loadHistory fetches the device list and the first page', () async {
    await cubit.loadHistory();

    expect(repository.deviceCalls, 1);
    expect(cubit.state.devices.map((d) => d.name), ['LED 1', 'LED 2', 'LED 3']);
    expect(repository.queries.single.page, 0);
    expect(cubit.state.actions.page, 1);
    expect(cubit.state.actions.data, isNotEmpty);
    expect(cubit.state.actions.data.length, lessThanOrEqualTo(cubit.state.actions.pageSize));
    expect(cubit.state.actions.pageCounts, greaterThan(1));
  });

  test('filtering by device asks the backend and shows only that device', () async {
    await cubit.loadHistory();

    await cubit.filterByDevice(2);

    expect(repository.queries.last.deviceId, 2);
    expect(cubit.state.selectedDeviceId, 2);
    expect(cubit.state.actions.page, 1);
    expect(cubit.state.actions.data, isNotEmpty);
    expect(cubit.state.actions.data.every((a) => a.deviceId == 2), isTrue);

    await cubit.filterByDevice(null);
    expect(repository.queries.last.deviceId, isNull);
  });

  test('paging goes to the backend and keeps the filters', () async {
    await cubit.loadHistory();
    await cubit.filterByAction(DeviceActionType.turnOn);

    await cubit.goToPage(2);
    expect(repository.queries.last.page, 1);
    expect(repository.queries.last.action, DeviceActionType.turnOn);
    expect(cubit.state.actions.page, 2);

    await cubit.changePageSize(50);
    expect(repository.queries.last.size, 50);
    expect(repository.queries.last.page, 0);
    expect(cubit.state.actions.page, 1);
    expect(cubit.state.actions.pageSize, 50);
    expect(cubit.state.selectedAction, DeviceActionType.turnOn);
  });

  test('result and time search filters are sent and applied', () async {
    await cubit.loadHistory();
    final sample = cubit.state.actions.data.first.timestamp;

    await cubit.filterByResult(DeviceActionResult.failed);
    expect(cubit.state.actions.data.every((a) => a.result == DeviceActionResult.failed), isTrue);

    await cubit.search(' ${sample.year} ');
    expect(repository.queries.last.query, '${sample.year}');
    expect(repository.queries.last.result, DeviceActionResult.failed);
    expect(cubit.state.actions.data.every((a) => a.timestamp.year == sample.year), isTrue);
  });

  test('refresh fetches the current page again and keeps the filters', () async {
    await cubit.loadHistory();
    await cubit.filterByDevice(1);
    final calls = repository.queries.length;

    await cubit.refresh();

    expect(repository.queries.length, calls + 1);
    expect(repository.queries.last.deviceId, 1);
    expect(cubit.state.selectedDeviceId, 1);
  });

  test('clear resets every filter and the search, and reloads the first page', () async {
    await cubit.loadHistory();
    await cubit.filterByDevice(2);
    await cubit.filterByAction(DeviceActionType.turnOn);
    await cubit.filterByResult(DeviceActionResult.failed);
    await cubit.search('2026');
    await cubit.goToPage(2);

    await cubit.clear();

    final query = repository.queries.last;
    expect(query.deviceId, isNull);
    expect(query.action, isNull);
    expect(query.result, isNull);
    expect(query.query, '');
    expect(query.page, 0);
    expect(cubit.state.selectedDeviceId, isNull);
    expect(cubit.state.selectedAction, isNull);
    expect(cubit.state.selectedResult, isNull);
    expect(cubit.state.searchQuery, '');
    expect(cubit.state.actions.page, 1);
  });
}
