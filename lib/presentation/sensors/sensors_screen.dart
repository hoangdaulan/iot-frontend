import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/core/di/injection.dart';
import 'package:gp1/core/utils/extensions/snack_bar_extension.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_reading.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/sensors/cubit/sensors_cubit.dart';
import 'package:gp1/presentation/widgets/app_info_chip.dart';
import 'package:gp1/presentation/widgets/table/app_table.dart';
import 'package:intl/intl.dart';

class SensorsScreen extends StatelessWidget {
  const SensorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SensorsCubit>()..loadSensorData(),
      child: BlocListener<SensorsCubit, SensorsState>(
        listener: (context, state) => context.handleFailure(state.failure),
        child: const SensorsView(),
      ),
    );
  }
}

class SensorsView extends StatefulWidget {
  const SensorsView({super.key});

  @override
  State<SensorsView> createState() => _SensorsViewState();
}

class _SensorsViewState extends State<SensorsView> {
  late final TextEditingController _searchController;
  late final TextEditingController _quickSearchController;

  @override
  void initState() {
    super.initState();
    final state = context.read<SensorsCubit>().state;
    _searchController = TextEditingController(text: state.searchQuery);
    _quickSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quickSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SensorsCubit>();
    final state = context.watch<SensorsCubit>().state;
    final timeFormat = DateFormat(state.precision.formatPattern);

    const labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.8,
      color: ColorName.labelSecondary,
    );

    return Column(
      children: [
        // ── Filter Bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Wrap(
            spacing: 24,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              // ── DATE & TIME RANGE ──
              SizedBox(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('DATE & TIME', style: labelStyle),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'DD/MM/YYYY HH:MM:SS',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 10, right: 8),
                          child: Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: ColorName.labelSecondary,
                          ),
                        ),
                        suffixIcon: state.searchQuery.isNotEmpty
                            ? IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  cubit.search('');
                                },
                              )
                            : null,
                      ),
                      onChanged: cubit.search,
                    ),
                  ],
                ),
              ),
              // ── SENSOR TYPE ──
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('SENSOR TYPE', style: labelStyle),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<SensorType?>(
                      initialValue: state.selectedType,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                      items: [
                        const DropdownMenuItem<SensorType?>(
                          value: null,
                          child: Text('All Sensors'),
                        ),
                        ...SensorType.values.map(
                          (type) => DropdownMenuItem(value: type, child: Text(type.label)),
                        ),
                      ],
                      onChanged: cubit.filterByType,
                    ),
                  ],
                ),
              ),
              // ── QUICK SEARCH ──
              SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('SEARCH', style: labelStyle),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _quickSearchController,
                      decoration: InputDecoration(
                        hintText: 'Search values or IDs',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 10, right: 8),
                          child: Icon(Icons.search, size: 18, color: ColorName.labelSecondary),
                        ),
                        suffixIcon: _quickSearchController.text.isNotEmpty
                            ? IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _quickSearchController.clear();
                                  cubit.filterByMinValue(null);
                                  cubit.filterByMaxValue(null);
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        setState(() {});
                        final doubleVal = double.tryParse(val);
                        if (doubleVal != null) {
                          cubit.filterByMinValue(doubleVal);
                          cubit.filterByMaxValue(doubleVal);
                        } else {
                          cubit.filterByMinValue(null);
                          cubit.filterByMaxValue(null);
                          cubit.search(val.isNotEmpty ? val : _searchController.text);
                        }
                      },
                    ),
                  ],
                ),
              ),
              // ── Refresh Button ──
              Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: FilledButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    _quickSearchController.clear();
                    cubit.refresh();
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh'),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Data Table ──
        Expanded(
          child: AppTable<SensorReading>(
            pagedList: state.readings,
            minWidth: 600,
            columns: [
              AppTableColumn(
                headerLabel: 'Sensor Type',
                width: 150,
                cellBuilder: (reading) => Center(
                  child: AppInfoChip(
                    label: reading.type.label,
                    icon: _iconForType(reading.type),
                    color: _colorForType(reading.type),
                  ),
                ),
              ),
              AppTableColumn(
                headerLabel: 'Value',
                width: 120,
                cellBuilder: (reading) => Center(
                  child: Text(
                    reading.value.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ),
              AppTableColumn(
                headerLabel: 'Unit',
                width: 80,
                cellBuilder: (reading) => Center(
                  child: Text(
                    reading.unit,
                    style: const TextStyle(color: ColorName.labelSecondary),
                  ),
                ),
              ),
              AppTableColumn(
                headerLabel: 'Timestamp',
                flex: 1,
                cellBuilder: (reading) => Center(
                  child: Text(
                    timeFormat.format(reading.timestamp),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
            onRefresh: () {
              _searchController.clear();
              _quickSearchController.clear();
              cubit.refresh();
            },
            onRowsPerPageChanged: cubit.changePageSize,
            onPageChanged: cubit.goToPage,
          ),
        ),
      ],
    );
  }

  IconData _iconForType(SensorType type) {
    return switch (type) {
      SensorType.temperature => Icons.thermostat,
      SensorType.humidity => Icons.water_drop,
      SensorType.light => Icons.light_mode,
    };
  }

  Color _colorForType(SensorType type) {
    return switch (type) {
      SensorType.temperature => ColorName.red,
      SensorType.humidity => ColorName.blue,
      SensorType.light => ColorName.orange,
    };
  }
}
