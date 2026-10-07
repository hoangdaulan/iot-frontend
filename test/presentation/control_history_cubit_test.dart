import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/presentation/control_history/cubit/control_history_cubit.dart';

import '../helpers/fake_device_repository.dart';

/// Searching by time is done by the backend and tested there; these tests check what the cubit
/// asks for and how it shows the pages it gets back.
void main() {
  late FakeDeviceRepository repository;
  late ControlHistoryCubit cubit;

  setUp(() {
    repository = FakeDeviceRepository();
    cubit = ControlHistoryCubit(repository);
  });

  test('loadHistory fetches the device list and the first page', () async {
    await cubit.loadHistory();

    expect(repository.deviceCalls, 1);
    expect(cubit.state.devices.map((d) => d.name), ['LED 1', 'LED 2', 'LED 3']);
    expect(repository.historyQueries.single.page, 0);
    expect(cubit.state.actions.page, 1);
    expect(cubit.state.actions.data, hasLength(20));
    expect(cubit.state.actions.pageCounts, 10);
  });

  test('filtering by device asks the backend and shows only that device', () async {
    await cubit.loadHistory();

    await cubit.filterByDevice(2);

    expect(repository.historyQueries.last.deviceId, 2);
    expect(cubit.state.selectedDeviceId, 2);
    expect(cubit.state.actions.page, 1);
    expect(cubit.state.actions.data, isNotEmpty);
    expect(cubit.state.actions.data.every((a) => a.deviceId == 2), isTrue);

    await cubit.filterByDevice(null);
    expect(repository.historyQueries.last.deviceId, isNull);
  });

  test('paging goes to the backend and keeps the filters', () async {
    await cubit.loadHistory();
    await cubit.filterByAction(DeviceActionType.turnOn);

    await cubit.goToPage(2);
    expect(repository.historyQueries.last.page, 1);
    expect(repository.historyQueries.last.action, DeviceActionType.turnOn);
    expect(cubit.state.actions.page, 2);

    await cubit.changePageSize(50);
    expect(repository.historyQueries.last.size, 50);
    expect(repository.historyQueries.last.page, 0);
    expect(cubit.state.actions.page, 1);
    expect(cubit.state.actions.pageSize, 50);
    expect(cubit.state.selectedAction, DeviceActionType.turnOn);
  });

  test('result and time search filters are sent with the query', () async {
    await cubit.loadHistory();

    await cubit.filterByResult(DeviceActionResult.failed);
    expect(cubit.state.actions.data.every((a) => a.result == DeviceActionResult.failed), isTrue);

    await cubit.search(' 2026/10 ');

    final query = repository.historyQueries.last;
    expect(query.query, '2026/10');
    expect(query.utcOffsetMinutes, DateTime.now().timeZoneOffset.inMinutes);
    expect(query.result, DeviceActionResult.failed);
    expect(cubit.state.searchQuery, '2026/10');
  });

  test('refresh fetches the current page again and keeps the filters', () async {
    await cubit.loadHistory();
    await cubit.filterByDevice(1);
    final calls = repository.historyQueries.length;

    await cubit.refresh();

    expect(repository.historyQueries.length, calls + 1);
    expect(repository.historyQueries.last.deviceId, 1);
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

    final query = repository.historyQueries.last;
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
