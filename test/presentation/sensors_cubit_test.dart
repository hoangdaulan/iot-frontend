import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/sensor_history_query.dart';
import 'package:gp1/data/models/dto/sensor_history_response.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_search_field.dart';
import 'package:gp1/data/repositories/mock/mock_sensor_repository.dart';
import 'package:gp1/presentation/sensors/cubit/sensors_cubit.dart';

/// Records the queries and delegates to the mock, which mirrors the backend search.
class _RecordingSensorRepository extends MockSensorRepository {
  final queries = <SensorHistoryQuery>[];

  @override
  Future<Result<SensorHistoryResponse>> getSensorHistory(SensorHistoryQuery query) {
    queries.add(query);
    return super.getSensorHistory(query);
  }
}

void main() {
  late _RecordingSensorRepository repository;
  late SensorsCubit cubit;

  setUp(() {
    repository = _RecordingSensorRepository();
    cubit = SensorsCubit(repository);
  });

  test('loadSensorData shows the first page of everything', () async {
    await cubit.loadSensorData();

    expect(repository.queries.single.page, 0);
    expect(repository.queries.single.searchField, SensorSearchField.all);
    expect(cubit.state.readings.page, 1);
    expect(cubit.state.readings.data, isNotEmpty);
  });

  test('search applies the field and query on the backend and returns to page 1', () async {
    await cubit.loadSensorData();
    await cubit.goToPage(3);
    expect(cubit.state.readings.page, 3);

    await cubit.search(SensorSearchField.humidity, ' ');

    final query = repository.queries.last;
    expect(query.searchField, SensorSearchField.humidity);
    expect(query.page, 0);
    expect(cubit.state.field, SensorSearchField.humidity);
    expect(cubit.state.readings.page, 1);
    expect(cubit.state.readings.data, isNotEmpty);
    expect(cubit.state.readings.data.every((r) => r.type == SensorType.humidity), isTrue);
  });

  test('a time search keeps only readings inside the typed period', () async {
    await cubit.loadSensorData();
    final sample = cubit.state.readings.data.first.timestamp;
    final hour =
        '${sample.year}/${sample.month.toString().padLeft(2, '0')}/'
        '${sample.day.toString().padLeft(2, '0')} ${sample.hour}';

    await cubit.search(SensorSearchField.time, hour);

    expect(cubit.state.readings.data, isNotEmpty);
    for (final reading in cubit.state.readings.data) {
      expect(reading.timestamp.hour, sample.hour);
      expect(reading.timestamp.day, sample.day);
    }
  });

  test('a value search matches the integer part', () async {
    await cubit.loadSensorData();
    final sample = cubit.state.readings.data.firstWhere((r) => r.type == SensorType.temperature);
    final integerPart = sample.value.floor();

    await cubit.search(SensorSearchField.temperature, '$integerPart');

    // The mock regenerates its data per call, so check the rule rather than the sample.
    expect(cubit.state.readings.data, isNotEmpty);
    for (final reading in cubit.state.readings.data) {
      expect(reading.type, SensorType.temperature);
      expect(reading.value.floor(), integerPart);
    }
  });

  test('All searches the sensor, the value and the time together', () async {
    await cubit.search(SensorSearchField.all, 'humid');
    expect(cubit.state.readings.data, isNotEmpty);
    expect(cubit.state.readings.data.every((r) => r.type == SensorType.humidity), isTrue);

    // Sensor id 3 is the light sensor; the number also matches values with that integer part.
    await cubit.search(SensorSearchField.all, '3');
    final types = cubit.state.readings.data.map((r) => r.type).toSet();
    expect(types, contains(SensorType.light));
    expect(
      cubit.state.readings.data.every((r) => r.type == SensorType.light || r.value.floor() == 3),
      isTrue,
    );
  });

  test('clear resets to all with an empty query', () async {
    await cubit.search(SensorSearchField.light, '400');

    await cubit.clear();

    expect(cubit.state.field, SensorSearchField.all);
    expect(cubit.state.query, '');
    expect(repository.queries.last.searchField, SensorSearchField.all);
    expect(repository.queries.last.searchQuery, '');
  });

  test('changing the page size and page keeps the applied search', () async {
    await cubit.search(SensorSearchField.temperature, '');

    await cubit.changePageSize(50);
    expect(repository.queries.last.size, 50);
    expect(repository.queries.last.searchField, SensorSearchField.temperature);

    await cubit.goToPage(2);
    expect(repository.queries.last.page, 1);
    expect(repository.queries.last.size, 50);
  });
}
