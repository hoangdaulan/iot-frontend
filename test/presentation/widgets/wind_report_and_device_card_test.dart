import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/presentation/dashboard/widgets/device_control_card.dart';
import 'package:gp1/presentation/wind_report/cubit/wind_report_cubit.dart';
import 'package:gp1/presentation/wind_report/wind_report_screen.dart';

import '../../helpers/fake_sensor_repository.dart';

void main() {
  testWidgets('a device card has a switch, the warning LED card does not', (tester) async {
    Widget card({ValueChanged<bool>? onToggle, bool isOn = true}) => MaterialApp(
      home: Scaffold(
        body: DeviceControlCard(
          title: 'LED',
          subtitle: 'LED',
          icon: Icons.light_mode,
          color: Colors.red,
          isOn: isOn,
          onToggle: onToggle,
          activeLabel: onToggle == null ? 'Warning' : 'Active',
        ),
      ),
    );

    await tester.pumpWidget(card(onToggle: (_) {}));
    expect(find.byType(Switch), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);

    await tester.pumpWidget(card());
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Warning'), findsOneWidget);
  });

  testWidgets('Wind Report shows one bar per day', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cubit = WindReportCubit(FakeSensorRepository());
    await cubit.load();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(value: cubit, child: const WindReportView()),
        ),
      ),
    );

    expect(find.text('Wind warnings per day - 2026-10'), findsOneWidget);
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.barGroups, hasLength(31));
    expect(chart.data.barGroups.first.barRods.single.toY, 3);
    expect(chart.data.barGroups[6].barRods.single.toY, 0); // day 7: a quiet day

    // The live refresh timer must not outlive the test.
    await cubit.close();
  });
}
