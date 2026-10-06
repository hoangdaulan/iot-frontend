import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/core/di/injection.dart';
import 'package:gp1/core/utils/extensions/snack_bar_extension.dart';
import 'package:gp1/data/models/device_action.dart';
import 'package:gp1/data/models/device_action_history_item.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/control_history/cubit/control_history_cubit.dart';
import 'package:gp1/presentation/widgets/app_info_chip.dart';
import 'package:gp1/presentation/widgets/table/app_table.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ControlHistoryCubit>();
    final state = context.watch<ControlHistoryCubit>().state;
    final timeFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

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
                child: DropdownButtonFormField<int?>(
                  // Rebuilt when the options or selection change.
                  key: ValueKey((state.devices.length, state.selectedDeviceId)),
                  initialValue: state.selectedDeviceId,
                  decoration: const InputDecoration(labelText: 'Device', isDense: true),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('All Devices')),
                    ...state.devices.map(
                      (d) => DropdownMenuItem<int?>(value: d.id, child: Text(d.name)),
                    ),
                  ],
                  onChanged: cubit.filterByDevice,
                ),
              ),
              // Search by device name or time; applied on Enter or the search icon
              SizedBox(
                width: 280,
                child: TextFormField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search time',
                    hintText: 'yyyy/MM/dd HH:mm:ss, e.g. 2026/10/06 11',
                    isDense: true,
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
                child: DropdownButtonFormField<DeviceActionType?>(
                  initialValue: state.selectedAction,
                  decoration: const InputDecoration(labelText: 'Action', isDense: true),
                  items: [
                    const DropdownMenuItem<DeviceActionType?>(
                      value: null,
                      child: Text('All Actions'),
                    ),
                    ...DeviceActionType.values.map(
                      (a) => DropdownMenuItem(value: a, child: Text(a.label)),
                    ),
                  ],
                  onChanged: cubit.filterByAction,
                ),
              ),
              // Status filter
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<DeviceActionResult?>(
                  initialValue: state.selectedResult,
                  decoration: const InputDecoration(labelText: 'Status', isDense: true),
                  items: [
                    const DropdownMenuItem<DeviceActionResult?>(
                      value: null,
                      child: Text('All Status'),
                    ),
                    ...DeviceActionResult.values
                        .where(
                          (r) => r != DeviceActionResult.pending && r != DeviceActionResult.unknown,
                        )
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.label))),
                  ],
                  onChanged: cubit.filterByResult,
                ),
              ),
              FilledButton.icon(
                onPressed: cubit.refresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
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
                flex: 2,
                cellBuilder: (action) => Center(
                  child: Text(
                    action.deviceName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              AppTableColumn(
                headerLabel: 'Action',
                width: 100,
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
                width: 120,
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
                flex: 2,
                cellBuilder: (action) => Center(
                  child: Text(
                    timeFormat.format(action.timestamp),
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
