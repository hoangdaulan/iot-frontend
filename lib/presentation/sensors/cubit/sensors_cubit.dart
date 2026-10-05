import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/app/constants/app_constants.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/sensor_history_query.dart';
import 'package:gp1/data/models/paged_list.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_reading.dart';
import 'package:gp1/data/repositories/sensor_repository.dart';
import 'package:gp1/presentation/sensors/models/sensor_series.dart';
import 'package:gp1/presentation/sensors/models/time_precision.dart';
import 'package:intl/intl.dart';

class SensorsState {
  final PagedList<SensorReading> readings;
  final SensorType? selectedType;
  final DateTime? startTime;
  final DateTime? endTime;
  final TimePrecision precision;
  final String searchQuery;
  final double? minValue;
  final double? maxValue;

  /// Aggregated readings per sensor type, ignoring the table-only filters.
  final Map<SensorType, SensorSeries> series;
  final Failure? failure;

  final List<SensorReading> _allReadings;

  const SensorsState({
    this.readings = const PagedList<SensorReading>(),
    this.selectedType,
    this.startTime,
    this.endTime,
    this.precision = TimePrecision.second,
    this.searchQuery = '',
    this.minValue,
    this.maxValue,
    this.series = const {},
    this.failure,
    List<SensorReading> allReadings = const [],
  }) : _allReadings = allReadings;

  SensorsState copyWith({
    PagedList<SensorReading>? readings,
    SensorType? Function()? selectedType,
    DateTime? Function()? startTime,
    DateTime? Function()? endTime,
    TimePrecision? precision,
    String? searchQuery,
    double? Function()? minValue,
    double? Function()? maxValue,
    Map<SensorType, SensorSeries>? series,
    Failure? failure,
    List<SensorReading>? allReadings,
  }) {
    return SensorsState(
      readings: readings ?? this.readings,
      selectedType: selectedType != null ? selectedType() : this.selectedType,
      startTime: startTime != null ? startTime() : this.startTime,
      endTime: endTime != null ? endTime() : this.endTime,
      precision: precision ?? this.precision,
      searchQuery: searchQuery ?? this.searchQuery,
      minValue: minValue != null ? minValue() : this.minValue,
      maxValue: maxValue != null ? maxValue() : this.maxValue,
      series: series ?? this.series,
      failure: failure,
      allReadings: allReadings ?? _allReadings,
    );
  }
}

class SensorsCubit extends Cubit<SensorsState> {
  SensorsCubit(this._sensorRepository) : super(const SensorsState());

  final SensorRepository _sensorRepository;

  Future<void> loadSensorData() async {
    // Filtering, aggregation and paging stay client-side over the most recent window.
    final result = await _sensorRepository.getSensorHistory(
      const SensorHistoryQuery(size: AppConstants.historyFetchSize),
    );
    switch (result) {
      case Success(data: final response):
        emit(state.copyWith(allReadings: response.toReadings()));
        _applyFilters(page: 1);
      case Failure():
        emit(state.copyWith(failure: result));
    }
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyFilters(page: 1);
  }

  void filterByType(SensorType? type) {
    emit(state.copyWith(selectedType: () => type));
    _applyFilters(page: 1);
  }

  void filterByMinValue(double? min) {
    emit(state.copyWith(minValue: () => min));
    _applyFilters(page: 1);
  }

  void filterByMaxValue(double? max) {
    emit(state.copyWith(maxValue: () => max));
    _applyFilters(page: 1);
  }

  void filterByStartTime(DateTime? start) {
    emit(state.copyWith(startTime: () => start));
    _applyFilters(page: 1);
  }

  void filterByEndTime(DateTime? end) {
    emit(state.copyWith(endTime: () => end));
    _applyFilters(page: 1);
  }

  void changePrecision(TimePrecision precision) {
    emit(state.copyWith(precision: precision));
    _applyFilters(page: 1);
  }

  void refresh() {
    emit(
      state.copyWith(
        searchQuery: '',
        minValue: () => null,
        maxValue: () => null,
        selectedType: () => null,
        startTime: () => null,
        endTime: () => null,
      ),
    );
    _applyFilters(page: 1);
  }

  void changePageSize(int newPageSize) => _applyFilters(page: 1, pageSize: newPageSize);
  void goToPage(int newPage) => _applyFilters(page: newPage);

  void _applyFilters({int? page, int? pageSize}) {
    var rawList = state._allReadings.toList();

    // 1. Filter raw list by start time and end time first
    if (state.startTime != null) {
      rawList = rawList.where((r) => !r.timestamp.isBefore(state.startTime!)).toList();
    }
    if (state.endTime != null) {
      rawList = rawList.where((r) => !r.timestamp.isAfter(state.endTime!)).toList();
    }

    // 2. Group and aggregate all readings by (sensorType, truncatedTimestamp) based on TimePrecision
    final Map<String, List<SensorReading>> groupedMap = {};
    for (final reading in rawList) {
      final truncated = state.precision.truncate(reading.timestamp);
      final key = '${reading.type.name}_${truncated.millisecondsSinceEpoch}';
      groupedMap.putIfAbsent(key, () => []).add(reading);
    }

    final List<SensorReading> allAggregatedReadings = [];
    groupedMap.forEach((key, groupReadings) {
      if (groupReadings.isEmpty) return;

      final first = groupReadings.first;
      final truncatedTimestamp = state.precision.truncate(first.timestamp);
      final averageValue =
          groupReadings.fold<double>(0.0, (sum, r) => sum + r.value) / groupReadings.length;

      // An aggregated row is identified by the first reading of its bucket.
      allAggregatedReadings.add(
        SensorReading(
          id: first.id,
          sensorId: first.sensorId,
          type: first.type,
          value: double.parse(averageValue.toStringAsFixed(1)),
          timestamp: truncatedTimestamp,
        ),
      );
    });

    // 3. Separate chart data per sensor type (sorted chronologically: oldest -> newest)
    final series = SensorSeries.group(allAggregatedReadings);

    // 4. Filter for table display (apply selectedType, minValue, maxValue, searchQuery)
    var tableReadings = allAggregatedReadings.toList();

    if (state.selectedType != null) {
      tableReadings = tableReadings.where((r) => r.type == state.selectedType).toList();
    }

    if (state.minValue != null) {
      tableReadings = tableReadings.where((r) => r.value >= state.minValue!).toList();
    }

    if (state.maxValue != null) {
      tableReadings = tableReadings.where((r) => r.value <= state.maxValue!).toList();
    }

    if (state.searchQuery.trim().isNotEmpty) {
      final q = state.searchQuery.trim().toLowerCase();
      final dtRange = _parseDateTimeQuery(q);

      final dmyFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
      final ymdFormat = DateFormat('yyyy/MM/dd HH:mm:ss');
      final dmyDashFormat = DateFormat('dd-MM-yyyy HH:mm:ss');
      final ymdDashFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

      tableReadings = tableReadings.where((r) {
        if (dtRange != null) {
          final isAfterOrEqualStart =
              r.timestamp.isAfter(dtRange.start) || r.timestamp.isAtSameMomentAs(dtRange.start);
          final isBeforeOrEqualEnd =
              r.timestamp.isBefore(dtRange.end) || r.timestamp.isAtSameMomentAs(dtRange.end);
          if (isAfterOrEqualStart && isBeforeOrEqualEnd) {
            return true;
          }
        }

        final strDmy = dmyFormat.format(r.timestamp).toLowerCase();
        final strYmd = ymdFormat.format(r.timestamp).toLowerCase();
        final strDmyDash = dmyDashFormat.format(r.timestamp).toLowerCase();
        final strYmdDash = ymdDashFormat.format(r.timestamp).toLowerCase();

        return strDmy.contains(q) ||
            strYmd.contains(q) ||
            strDmyDash.contains(q) ||
            strYmdDash.contains(q) ||
            r.type.label.toLowerCase().contains(q) ||
            r.value.toString().contains(q) ||
            r.unit.toLowerCase().contains(q);
      }).toList();
    }

    // Sort table newest first; same-time rows in sensor type order, independent of API order
    tableReadings.sort((a, b) {
      final byTime = b.timestamp.compareTo(a.timestamp);
      return byTime != 0 ? byTime : a.type.index.compareTo(b.type.index);
    });

    // 5. Pagination
    final currentPage = page ?? state.readings.page;
    final currentPageSize = pageSize ?? state.readings.pageSize;
    final totalPages = (tableReadings.length / currentPageSize).ceil().clamp(
      1,
      double.maxFinite.toInt(),
    );

    final startIndex = (currentPage - 1) * currentPageSize;
    final endIndex = (startIndex + currentPageSize).clamp(0, tableReadings.length);
    final pageData = startIndex < tableReadings.length
        ? tableReadings.sublist(startIndex, endIndex)
        : <SensorReading>[];

    emit(
      state.copyWith(
        readings: PagedList(
          data: pageData,
          page: currentPage,
          pageSize: currentPageSize,
          pageCounts: totalPages,
        ),
        series: series,
      ),
    );
  }

  DateTimeRange? _parseDateTimeQuery(String query) {
    final q = query.trim();
    if (q.isEmpty) return null;

    // 1. yyyy/MM/dd HH:mm:ss or yyyy-MM-dd HH:mm:ss or yyyy/MM/dd or yyyy-MM or yyyy
    final ymdRegex = RegExp(
      r'^(\d{4})(?:[/-](\d{1,2})(?:[/-](\d{1,2})(?:[\sT](\d{1,2})(?::(\d{1,2})(?::(\d{1,2}))?)?)?)?)?$',
    );
    var match = ymdRegex.firstMatch(q);
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = match.group(2) != null ? int.parse(match.group(2)!) : null;
      final day = match.group(3) != null ? int.parse(match.group(3)!) : null;
      final hour = match.group(4) != null ? int.parse(match.group(4)!) : null;
      final minute = match.group(5) != null ? int.parse(match.group(5)!) : null;
      final second = match.group(6) != null ? int.parse(match.group(6)!) : null;

      return _buildRange(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second,
      );
    }

    // 2. dd/MM/yyyy HH:mm:ss or dd-MM-yyyy HH:mm:ss or dd/MM/yyyy
    final dmyRegex = RegExp(
      r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})(?:[\sT](\d{1,2})(?::(\d{1,2})(?::(\d{1,2}))?)?)?$',
    );
    match = dmyRegex.firstMatch(q);
    if (match != null) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      final hour = match.group(4) != null ? int.parse(match.group(4)!) : null;
      final minute = match.group(5) != null ? int.parse(match.group(5)!) : null;
      final second = match.group(6) != null ? int.parse(match.group(6)!) : null;

      return _buildRange(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second,
      );
    }

    return null;
  }

  DateTimeRange? _buildRange({
    required int year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
  }) {
    if (month == null || month < 1 || month > 12) {
      final start = DateTime(year, 1, 1);
      final end = DateTime(year, 12, 31, 23, 59, 59, 999);
      return DateTimeRange(start: start, end: end);
    }

    final maxDaysInMonth = DateTime(year, month + 1, 0).day;

    if (day == null || day < 1 || day > maxDaysInMonth) {
      final start = DateTime(year, month, 1);
      final end = DateTime(year, month, maxDaysInMonth, 23, 59, 59, 999);
      return DateTimeRange(start: start, end: end);
    }

    if (hour == null || hour < 0 || hour > 23) {
      final start = DateTime(year, month, day);
      final end = DateTime(year, month, day, 23, 59, 59, 999);
      return DateTimeRange(start: start, end: end);
    }

    if (minute == null || minute < 0 || minute > 59) {
      final start = DateTime(year, month, day, hour);
      final end = DateTime(year, month, day, hour, 59, 59, 999);
      return DateTimeRange(start: start, end: end);
    }

    if (second == null || second < 0 || second > 59) {
      final start = DateTime(year, month, day, hour, minute);
      final end = DateTime(year, month, day, hour, minute, 59, 999);
      return DateTimeRange(start: start, end: end);
    }

    final start = DateTime(year, month, day, hour, minute, second);
    final end = DateTime(year, month, day, hour, minute, second, 999);
    return DateTimeRange(start: start, end: end);
  }
}
