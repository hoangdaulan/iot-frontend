import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/core/di/injection.dart';
import 'package:gp1/core/utils/extensions/snack_bar_extension.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/data/models/sensor_reading.dart';
import 'package:gp1/data/models/sensor_search_field.dart';
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
  late final TextEditingController _queryController;
  late SensorSearchField _field;

  @override
  void initState() {
    super.initState();
    final state = context.read<SensorsCubit>().state;
    _field = state.field;
    _queryController = TextEditingController(text: state.query);
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _search() => context.read<SensorsCubit>().search(_field, _queryController.text);

  void _clear() {
    setState(() => _field = SensorSearchField.all);
    _queryController.clear();
    context.read<SensorsCubit>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SensorsCubit>();
    final state = context.watch<SensorsCubit>().state;
    final timeFormat = DateFormat('yyyy/MM/dd HH:mm:ss');

    return Column(
      children: [
        // ── Filter Bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // ── Field ──
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<SensorSearchField>(
                  // Rebuilt on change so Clear can reset the selection.
                  key: ValueKey(_field),
                  initialValue: _field,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                  items: [
                    for (final field in SensorSearchField.values)
                      DropdownMenuItem(value: field, child: Text(field.label)),
                  ],
                  onChanged: (field) {
                    setState(() => _field = field ?? SensorSearchField.all);
                    _search();
                  },
                ),
              ),
              // ── Query ──
              SizedBox(
                width: 320,
                child: TextFormField(
                  controller: _queryController,
                  decoration: InputDecoration(
                    hintText: _field.hint,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  textInputAction: TextInputAction.search,
                  // Dropdown changes filter at once; the text is applied on Enter.
                  onFieldSubmitted: (_) => _search(),
                ),
              ),
              // ── Clear ──
              OutlinedButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Clear filter'),
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
            onRefresh: cubit.refresh,
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
