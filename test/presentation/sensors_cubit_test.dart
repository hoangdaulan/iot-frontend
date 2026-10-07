import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_search_field.dart';
import 'package:gp1/presentation/sensors/cubit/sensors_cubit.dart';

import '../helpers/fake_sensor_repository.dart';

/// The search itself (`filter`/`q`) is done by the backend and tested there; these tests check
/// what the cubit asks for and how it shows the pages it gets back.
void main() {
  late FakeSensorRepository repository;
  late SensorsCubit cubit;

  setUp(() {
    repository = FakeSensorRepository();
    cubit = SensorsCubit(repository);
  });

  test('loadSensorData shows the first page of everything', () async {
    await cubit.loadSensorData();

    final query = repository.queries.single;
    expect(query.page, 0);
    expect(query.size, 20);
    expect(query.searchField, SensorSearchField.all);
    expect(cubit.state.readings.page, 1);
    expect(cubit.state.readings.data, hasLength(20));
    expect(cubit.state.readings.pageCounts, greaterThan(1));
  });

  test('search sends the field and the trimmed query, and returns to page 1', () async {
    await cubit.loadSensorData();
    await cubit.goToPage(3);
    expect(cubit.state.readings.page, 3);

    await cubit.search(SensorSearchField.time, ' 2026/10/06 11 ');

    final query = repository.queries.last;
    expect(query.searchField, SensorSearchField.time);
    expect(query.searchQuery, '2026/10/06 11');
    expect(query.utcOffsetMinutes, DateTime.now().timeZoneOffset.inMinutes);
    expect(query.page, 0);
    expect(cubit.state.field, SensorSearchField.time);
    expect(cubit.state.query, '2026/10/06 11');
    expect(cubit.state.readings.page, 1);
  });

  test('a type filter sends the type as the field', () async {
    await cubit.search(SensorSearchField.humidity, '60');

    expect(repository.queries.last.searchField, SensorSearchField.humidity);
    expect(repository.queries.last.searchQuery, '60');
    expect(cubit.state.field, SensorSearchField.humidity);
  });

  test('clear resets to all with an empty query', () async {
    await cubit.search(SensorSearchField.light, '400');

    await cubit.clear();

    expect(cubit.state.field, SensorSearchField.all);
    expect(cubit.state.query, '');
    expect(repository.queries.last.searchField, SensorSearchField.all);
    expect(repository.queries.last.searchQuery, '');
    expect(repository.queries.last.page, 0);
  });

  test('changing the page size and page keeps the applied search', () async {
    await cubit.search(SensorSearchField.temperature, '');

    await cubit.changePageSize(50);
    expect(repository.queries.last.size, 50);
    expect(repository.queries.last.searchField, SensorSearchField.temperature);

    await cubit.goToPage(2);
    expect(repository.queries.last.page, 1);
    expect(repository.queries.last.size, 50);
    expect(cubit.state.readings.page, 2);
    expect(cubit.state.readings.pageSize, 50);
  });

  test('a failed request keeps the page and reports the failure', () async {
    await cubit.loadSensorData();
    final shown = cubit.state.readings;
    repository.historyFailure = const Failure(code: 500, message: 'Internal server error');

    await cubit.goToPage(2);

    expect(cubit.state.failure?.message, 'Internal server error');
    expect(cubit.state.readings, shown);
  });

  test('a page shows readings of every type', () async {
    await cubit.loadSensorData();

    expect(cubit.state.readings.data.map((r) => r.type).toSet(), SensorType.values.toSet());
  });
}
