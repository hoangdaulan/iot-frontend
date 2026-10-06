import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/device.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/device_action_history_item.dart';
import 'package:gp1/data/models/dto/device_history_query.dart';
import 'package:gp1/data/models/paged_list.dart';
import 'package:gp1/data/repositories/device_repository.dart';

class ControlHistoryState {
  const ControlHistoryState({
    this.actions = const PagedList<DeviceActionHistoryItem>(),
    this.devices = const [],
    this.selectedDeviceId,
    this.selectedAction,
    this.selectedResult,
    this.searchQuery = '',
    this.failure,
  });

  final PagedList<DeviceActionHistoryItem> actions;

  /// The devices to filter by, from the `devices` table.
  final List<Device> devices;
  final int? selectedDeviceId;
  final DeviceActionType? selectedAction;
  final DeviceActionResult? selectedResult;
  final String searchQuery;
  final Failure? failure;

  ControlHistoryState copyWith({
    PagedList<DeviceActionHistoryItem>? actions,
    List<Device>? devices,
    int? Function()? selectedDeviceId,
    DeviceActionType? Function()? selectedAction,
    DeviceActionResult? Function()? selectedResult,
    String? searchQuery,
    Failure? failure,
  }) {
    return ControlHistoryState(
      actions: actions ?? this.actions,
      devices: devices ?? this.devices,
      selectedDeviceId: selectedDeviceId != null ? selectedDeviceId() : this.selectedDeviceId,
      selectedAction: selectedAction != null ? selectedAction() : this.selectedAction,
      selectedResult: selectedResult != null ? selectedResult() : this.selectedResult,
      searchQuery: searchQuery ?? this.searchQuery,
      failure: failure,
    );
  }
}

/// The control history table. Filtering, searching and paging are done by the backend.
class ControlHistoryCubit extends Cubit<ControlHistoryState> {
  ControlHistoryCubit(this._deviceRepository) : super(const ControlHistoryState());

  final DeviceRepository _deviceRepository;

  /// Loads the device list for the filter, then the first page of history.
  Future<void> loadHistory() async {
    final devicesResult = await _deviceRepository.getDevices();
    if (devicesResult case Success(data: final devices)) {
      emit(state.copyWith(devices: devices));
    }
    await _load(page: 1);
    if (devicesResult case Failure()) emit(state.copyWith(failure: devicesResult));
  }

  Future<void> search(String query) => _load(page: 1, searchQuery: query.trim());

  Future<void> filterByDevice(int? deviceId) => _load(page: 1, selectedDeviceId: () => deviceId);

  Future<void> filterByAction(DeviceActionType? action) =>
      _load(page: 1, selectedAction: () => action);

  Future<void> filterByResult(DeviceActionResult? result) =>
      _load(page: 1, selectedResult: () => result);

  /// Back to all devices, actions and results with no search.
  Future<void> clear() => _load(
    page: 1,
    searchQuery: '',
    selectedDeviceId: () => null,
    selectedAction: () => null,
    selectedResult: () => null,
  );

  /// Fetches the history again, so new actions show up, and keeps the current filters.
  Future<void> refresh() => _load(page: state.actions.page);

  Future<void> changePageSize(int pageSize) => _load(page: 1, pageSize: pageSize);

  Future<void> goToPage(int page) => _load(page: page);

  Future<void> _load({
    required int page,
    int? pageSize,
    String? searchQuery,
    int? Function()? selectedDeviceId,
    DeviceActionType? Function()? selectedAction,
    DeviceActionResult? Function()? selectedResult,
  }) async {
    final deviceId = selectedDeviceId != null ? selectedDeviceId() : state.selectedDeviceId;
    final action = selectedAction != null ? selectedAction() : state.selectedAction;
    final result = selectedResult != null ? selectedResult() : state.selectedResult;
    final query = searchQuery ?? state.searchQuery;
    final size = pageSize ?? state.actions.pageSize;

    final response = await _deviceRepository.getControlHistory(
      DeviceHistoryQuery(
        deviceId: deviceId,
        action: action,
        result: result,
        query: query,
        utcOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
        page: page - 1,
        size: size,
      ),
    );

    switch (response) {
      case Success(data: final data):
        emit(
          state.copyWith(
            selectedDeviceId: () => deviceId,
            selectedAction: () => action,
            selectedResult: () => result,
            searchQuery: query,
            actions: PagedList(
              data: data.content,
              page: page,
              pageSize: size,
              pageCounts: data.totalPages < 1 ? 1 : data.totalPages,
            ),
          ),
        );
      case Failure():
        emit(state.copyWith(failure: response));
    }
  }
}
