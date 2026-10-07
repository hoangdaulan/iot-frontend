import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/core/di/injection.dart';
import 'package:gp1/core/utils/extensions/snack_bar_extension.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/dashboard/cubit/dashboard_cubit.dart';
import 'package:gp1/presentation/dashboard/widgets/device_control_card.dart';
import 'package:gp1/presentation/dashboard/widgets/sensor_chart.dart';
import 'package:gp1/presentation/dashboard/widgets/sensor_stat_card.dart';
import 'package:gp1/presentation/sensors/models/sensor_series.dart';
import 'package:gp1/presentation/widgets/app_loading.dart';
import 'package:gp1/presentation/widgets/my_app_bar.dart';
import 'package:gp1/presentation/widgets/responsive_layout.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DashboardCubit>()..loadDashboard(),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: MyAppBar(
            title: const Text('Dashboard'),
            actions: [
              IconButton(
                onPressed: context.read<DashboardCubit>().refreshLatestSensorData,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: const DashboardView(),
        ),
      ),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardCubit, DashboardState>(
      listener: (context, state) => context.handleFailure(state.failure),
      builder: (context, state) {
        if (state.isLoading) {
          return const AppLoading(size: 40);
        }

        final temperature = state.series.of(SensorType.temperature);
        final humidity = state.series.of(SensorType.humidity);
        final light = state.series.of(SensorType.light);
        final origin = state.windowStart ?? DateTime.now();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section Title: Live Sensors ──
              const _SectionTitle(title: 'Live Sensors', icon: Icons.sensors),
              const SizedBox(height: 12),

              // ── Sensor Stat Cards ──
              _ResponsiveGrid(
                children: [
                  SensorStatCard(
                    title: 'Temperature',
                    value: '${temperature.latestValue}',
                    unit: '°C',
                    icon: Icons.thermostat,
                    color: ColorName.red,
                  ),
                  SensorStatCard(
                    title: 'Humidity',
                    value: '${humidity.latestValue}',
                    unit: '%',
                    icon: Icons.water_drop,
                    color: ColorName.blue,
                  ),
                  SensorStatCard(
                    title: 'Light',
                    value: '${light.latestValue}',
                    unit: 'lux',
                    icon: Icons.light_mode,
                    color: ColorName.yellow,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Section Title: Today's Charts ──
              const _SectionTitle(title: 'Last 24 Hours', icon: Icons.show_chart),
              const SizedBox(height: 12),

              // ── Charts ──
              _ResponsiveGrid(
                children: [
                  SensorChart(
                    title: 'Temperature',
                    unit: '°C',
                    color: ColorName.red,
                    yMarginFraction: 0.5,
                    yMinMargin: 2,
                    origin: origin,
                    dataPoints: trendSpots(temperature.readings, origin: origin),
                  ),
                  SensorChart(
                    title: 'Humidity',
                    unit: '%',
                    color: ColorName.blue,
                    origin: origin,
                    dataPoints: trendSpots(humidity.readings, origin: origin),
                  ),
                  SensorChart(
                    title: 'Light',
                    unit: 'lux',
                    color: ColorName.yellow,
                    origin: origin,
                    dataPoints: trendSpots(light.readings, origin: origin),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Section Title: Device Controls ──
              const _SectionTitle(title: 'Device Controls', icon: Icons.toggle_on),
              const SizedBox(height: 12),

              // ── Device Control Cards ──
              _ResponsiveGrid(
                children: [
                  for (final device in state.devices)
                    DeviceControlCard(
                      title: device.name,
                      subtitle: device.type,
                      icon: Icons.light_mode,
                      color: _deviceColor(device.id),
                      isOn: device.isOn,
                      onToggle: (isOn) =>
                          context.read<DashboardCubit>().setDeviceOn(device.id, isOn),
                    ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

/// Accent color of a device card: LED 1 red, LED 2 yellow, LED 3 blue.
Color _deviceColor(int deviceId) => switch (deviceId) {
  1 => ColorName.red,
  3 => ColorName.blue,
  _ => ColorName.yellow,
};

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: ColorName.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ColorName.labelPrimary,
          ),
        ),
      ],
    );
  }
}

/// Equal-width columns on wide screens, stacked on narrow ones.
class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      spacing: 12,
      items: [for (final child in children) ResponsiveItem(flex: 1, child: child)],
    );
  }
}
