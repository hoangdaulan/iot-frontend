import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/app/constants/app_constants.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/device_action_history_item.dart';
import 'package:gp1/data/models/dto/device_history_query.dart';
import 'package:gp1/data/models/paged_list.dart';
import 'package:gp1/data/repositories/device_repository.dart';
import 'package:intl/intl.dart';

class ControlHistoryState {
  final PagedList<DeviceActionHistoryItem> actions;
  final DeviceActionType? selectedAction;
  final DeviceActionResult? selectedResult;
  final DateTimeRange? dateRange;
  final String searchQuery;
  final Failure? failure;
  final List<DeviceActionHistoryItem> _allActions;

  const ControlHistoryState({
    this.actions = const PagedList<DeviceActionHistoryItem>(),
    this.selectedAction,
    this.selectedResult,
    this.dateRange,
    this.searchQuery = '',
    this.failure,
    List<DeviceActionHistoryItem> allActions = const [],
  }) : _allActions = allActions;

  ControlHistoryState copyWith({
    PagedList<DeviceActionHistoryItem>? actions,
    DeviceActionType? Function()? selectedAction,
    DeviceActionResult? Function()? selectedResult,
    DateTimeRange? Function()? dateRange,
    String? searchQuery,
    Failure? failure,
    List<DeviceActionHistoryItem>? allActions,
  }) {
    return ControlHistoryState(
      actions: actions ?? this.actions,
      selectedAction: selectedAction != null ? selectedAction() : this.selectedAction,
      selectedResult: selectedResult != null ? selectedResult() : this.selectedResult,
      dateRange: dateRange != null ? dateRange() : this.dateRange,
      searchQuery: searchQuery ?? this.searchQuery,
      failure: failure,
      allActions: allActions ?? _allActions,
    );
  }
}

class ControlHistoryCubit extends Cubit<ControlHistoryState> {
  ControlHistoryCubit(this._deviceRepository) : super(const ControlHistoryState());

  final DeviceRepository _deviceRepository;

  Future<void> loadHistory() async {
    // Filtering, search and paging stay client-side over the most recent window.
    final result = await _deviceRepository.getControlHistory(
      const DeviceHistoryQuery(size: AppConstants.historyFetchSize),
    );
    switch (result) {
      case Success(data: final page):
        emit(state.copyWith(allActions: page.content));
        _applyFilters(page: 1);
      case Failure():
        emit(state.copyWith(failure: result));
    }
  }

  void search(String query) {
    emit(state.copyWith(searchQuery: query));
    _applyFilters(page: 1);
  }

  void filterByAction(DeviceActionType? action) {
    emit(state.copyWith(selectedAction: () => action));
    _applyFilters(page: 1);
  }

  void filterByResult(DeviceActionResult? result) {
    emit(state.copyWith(selectedResult: () => result));
    _applyFilters(page: 1);
  }

  void filterByDateRange(DateTimeRange? range) {
    emit(state.copyWith(dateRange: () => range));
    _applyFilters(page: 1);
  }

  void refresh() => _applyFilters(page: 1);
  void changePageSize(int newPageSize) => _applyFilters(page: 1, pageSize: newPageSize);
  void goToPage(int newPage) => _applyFilters(page: newPage);

  void _applyFilters({int? page, int? pageSize}) {
    var filtered = state._allActions.toList();

    if (state.selectedAction != null) {
      filtered = filtered.where((a) => a.action == state.selectedAction).toList();
    }

    if (state.selectedResult != null) {
      filtered = filtered.where((a) => a.result == state.selectedResult).toList();
    }

    if (state.dateRange != null) {
      filtered = filtered.where((a) {
        return a.timestamp.isAfter(state.dateRange!.start) &&
            a.timestamp.isBefore(state.dateRange!.end);
      }).toList();
    }

    if (state.searchQuery.trim().isNotEmpty) {
      final q = state.searchQuery.trim().toLowerCase();
      final dtRange = _parseDateTimeQuery(q);

      final dmyFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
      final ymdFormat = DateFormat('yyyy/MM/dd HH:mm:ss');
      final dmyDashFormat = DateFormat('dd-MM-yyyy HH:mm:ss');
      final ymdDashFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

      filtered = filtered.where((a) {
        if (dtRange != null) {
          final isAfterOrEqualStart =
              a.timestamp.isAfter(dtRange.start) || a.timestamp.isAtSameMomentAs(dtRange.start);
          final isBeforeOrEqualEnd =
              a.timestamp.isBefore(dtRange.end) || a.timestamp.isAtSameMomentAs(dtRange.end);
          if (isAfterOrEqualStart && isBeforeOrEqualEnd) {
            return true;
          }
        }

        final strDmy = dmyFormat.format(a.timestamp).toLowerCase();
        final strYmd = ymdFormat.format(a.timestamp).toLowerCase();
        final strDmyDash = dmyDashFormat.format(a.timestamp).toLowerCase();
        final strYmdDash = ymdDashFormat.format(a.timestamp).toLowerCase();

        return strDmy.contains(q) ||
            strYmd.contains(q) ||
            strDmyDash.contains(q) ||
            strYmdDash.contains(q) ||
            a.deviceName.toLowerCase().contains(q) ||
            a.action.label.toLowerCase().contains(q) ||
            a.result.label.toLowerCase().contains(q);
      }).toList();
    }

    final currentPage = page ?? state.actions.page;
    final currentPageSize = pageSize ?? state.actions.pageSize;
    final totalPages = (filtered.length / currentPageSize).ceil().clamp(
      1,
      double.maxFinite.toInt(),
    );

    final startIndex = (currentPage - 1) * currentPageSize;
    final endIndex = (startIndex + currentPageSize).clamp(0, filtered.length);
    final pageData = startIndex < filtered.length
        ? filtered.sublist(startIndex, endIndex)
        : <DeviceActionHistoryItem>[];

    emit(
      state.copyWith(
        actions: PagedList(
          data: pageData,
          page: currentPage,
          pageSize: currentPageSize,
          pageCounts: totalPages,
        ),
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
