import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/app/constants/app_constants.dart';
import 'package:gp1/core/di/injection.dart';
import 'package:gp1/core/utils/extensions/date_time_extension.dart';
import 'package:gp1/core/utils/extensions/snack_bar_extension.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/device_action_history_item.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/control_history/cubit/control_history_cubit.dart';
import 'package:gp1/presentation/widgets/app_info_chip.dart';
import 'package:gp1/presentation/widgets/app_text_field.dart';
import 'package:gp1/presentation/widgets/dropdown/app_dropdown.dart';
import 'package:gp1/presentation/widgets/models/app_option.dart';
import 'package:gp1/presentation/widgets/table/app_table.dart';

class ControlHistoryScreen extends StatelessWidget {
  const ControlHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ControlHistoryCubit>()..loadHistory(),
      child: BlocListener<ControlHistoryCubit, ControlHistoryState>(
        listener: (context, state) => context.handleFailure(state.failure),
        child: const ControlHistoryView(),
      ),
    );
  }
}

class ControlHistoryView extends StatefulWidget {
  const ControlHistoryView({super.key});

  @override
  State<ControlHistoryView> createState() => _ControlHistoryViewState();
}

class _ControlHistoryViewState extends State<ControlHistoryView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: context.read<ControlHistoryCubit>().state.searchQuery,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static final _actionOptions = [
    const AppOption<DeviceActionType>(null, 'All Actions'),
    for (final action in DeviceActionType.values) AppOption(action, action.label),
  ];

  static final _resultOptions = [
    const AppOption<DeviceActionResult>(null, 'All Status'),
    for (final result in DeviceActionResult.values)
      if (result != DeviceActionResult.pending && result != DeviceActionResult.unknown)
        AppOption(result, result.label),
  ];

  /// The option standing for [value], or the "All" entry (null value) when nothing is selected.
  static AppOption<T> _selected<T>(List<AppOption<T>> options, T? value) =>
      options.firstWhere((option) => option.value == value, orElse: () => options.first);

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ControlHistoryCubit>();
    final state = context.watch<ControlHistoryCubit>().state;
    final deviceOptions = [
      const AppOption<int>(null, 'All Devices'),
      for (final device in state.devices) AppOption(device.id, device.name),
    ];

    return Column(
      children: [
        // ── Filter Bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Device filter, from the devices table
              SizedBox(
                width: 160,
                child: AppDropdown<AppOption<int>>.single(
                  searchType: AppDropdownSearchType.none,
                  labelText: 'Device',
                  items: (_) => deviceOptions,
                  selectedItem: _selected(deviceOptions, state.selectedDeviceId),
                  onChanged: (option) => cubit.filterByDevice(option?.value),
                ),
              ),
              // Search by device name or time; applied on Enter or the search icon
              SizedBox(
                width: 280,
                child: AppTextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search time',
                    hintText: 'yyyy/MM/dd HH:mm:ss, e.g. 2026/10/06 11',
                    prefixIcon: IconButton(
                      icon: const Icon(Icons.search, size: 20),
                      onPressed: () => cubit.search(_searchController.text),
                    ),
                    suffixIcon: state.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              cubit.search('');
                            },
                          )
                        : null,
                  ),
                  textInputAction: TextInputAction.search,
                  onFieldSubmitted: cubit.search,
                ),
              ),
              // Action filter (ON/OFF)
              SizedBox(
                width: 140,
                child: AppDropdown<AppOption<DeviceActionType>>.single(
                  searchType: AppDropdownSearchType.none,
                  labelText: 'Action',
                  items: (_) => _actionOptions,
                  selectedItem: _selected(_actionOptions, state.selectedAction),
                  onChanged: (option) => cubit.filterByAction(option?.value),
                ),
              ),
              // Status filter
              SizedBox(
                width: 140,
                child: AppDropdown<AppOption<DeviceActionResult>>.single(
                  searchType: AppDropdownSearchType.none,
                  labelText: 'Status',
                  items: (_) => _resultOptions,
                  selectedItem: _selected(_resultOptions, state.selectedResult),
                  onChanged: (option) => cubit.filterByResult(option?.value),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  cubit.clear();
                },
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Clear filter'),
              ),
            ],
          ),
        ),
        const Divider(),
        // ── Table ──
        Expanded(
          child: AppTable<DeviceActionHistoryItem>(
            pagedList: state.actions,
            minWidth: 700,
            columns: [
              AppTableColumn(
                headerLabel: 'Device',
                flex: 1,
                cellBuilder: (action) => Center(
                  child: Text(
                    action.deviceName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              AppTableColumn(
                headerLabel: 'Executor',
                flex: 1,
                cellBuilder: (action) => Center(
                  child: Text(
                    action.user?.displayName ?? '—',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              AppTableColumn(
                headerLabel: 'Action',
                flex: 1,
                cellBuilder: (action) => Center(
                  child: AppInfoChip(
                    label: action.action.label,
                    color: action.action == DeviceActionType.turnOn
                        ? ColorName.green
                        : ColorName.orange,
                  ),
                ),
              ),
              AppTableColumn(
                headerLabel: 'Status',
                flex: 1,
                cellBuilder: (action) => Center(
                  child: AppInfoChip(
                    label: action.result.label,
                    icon: action.result == DeviceActionResult.success
                        ? Icons.check_circle_outline
                        : Icons.error_outline,
                    color: action.result == DeviceActionResult.success
                        ? ColorName.green
                        : ColorName.red,
                  ),
                ),
              ),
              AppTableColumn(
                headerLabel: 'Timestamp',
                flex: 1,
                cellBuilder: (action) => Center(
                  child: Text(
                    action.timestamp.toFormatString(pattern: AppConstants.dateTimeFormat),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
            onRefresh: cubit.refresh,
            onRowsPerPageChanged: cubit.changePageSize,
            onPageChanged: cubit.goToPage,
          ),
        ),
      ],
    );
  }
}
