import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/sensor_history_query.dart';
import 'package:gp1/data/models/paged_list.dart';
import 'package:gp1/data/models/sensor_reading.dart';
import 'package:gp1/data/models/sensor_search_field.dart';
import 'package:gp1/data/repositories/sensor_repository.dart';

class SensorsState {
  const SensorsState({
    this.readings = const PagedList<SensorReading>(),
    this.field = SensorSearchField.all,
    this.query = '',
    this.failure,
  });

  final PagedList<SensorReading> readings;

  /// The search applied to [readings]; it changes only when the user presses Search or Clear.
  final SensorSearchField field;
  final String query;
  final Failure? failure;

  SensorsState copyWith({
    PagedList<SensorReading>? readings,
    SensorSearchField? field,
    String? query,
    Failure? failure,
  }) {
    return SensorsState(
      readings: readings ?? this.readings,
      field: field ?? this.field,
      query: query ?? this.query,
      failure: failure,
    );
  }
}

/// The sensor history table. Searching and paging are done by the backend.
class SensorsCubit extends Cubit<SensorsState> {
  SensorsCubit(this._sensorRepository) : super(const SensorsState());

  final SensorRepository _sensorRepository;

  Future<void> loadSensorData() => _load(page: 1);

  /// Applies [field] and [query] and shows the first page of matches.
  Future<void> search(SensorSearchField field, String query) =>
      _load(page: 1, field: field, query: query.trim());

  /// Back to all readings with an empty query.
  Future<void> clear() => _load(page: 1, field: SensorSearchField.all, query: '');

  /// Reloads the current page with the applied search.
  Future<void> refresh() => _load(page: state.readings.page);

  Future<void> changePageSize(int pageSize) => _load(page: 1, pageSize: pageSize);

  Future<void> goToPage(int page) => _load(page: page);

  Future<void> _load({
    required int page,
    int? pageSize,
    SensorSearchField? field,
    String? query,
  }) async {
    final nextField = field ?? state.field;
    final nextQuery = query ?? state.query;
    final size = pageSize ?? state.readings.pageSize;

    final result = await _sensorRepository.getSensorHistory(
      SensorHistoryQuery(
        searchField: nextField,
        searchQuery: nextQuery,
        utcOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
        page: page - 1,
        size: size,
      ),
    );

    switch (result) {
      case Success(data: final response):
        emit(
          state.copyWith(
            field: nextField,
            query: nextQuery,
            readings: PagedList(
              data: response.toReadings(),
              page: page,
              pageSize: size,
              pageCounts: response.totalPages < 1 ? 1 : response.totalPages,
            ),
          ),
        );
      case Failure():
        emit(state.copyWith(failure: result));
    }
  }
}
