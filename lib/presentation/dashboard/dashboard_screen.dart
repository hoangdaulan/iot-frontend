import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/core/di/injection.dart';
import 'package:gp1/core/utils/extensions/snack_bar_extension.dart';
import 'package:gp1/data/models/sensor.dart';
import 'package:gp1/presentation/dashboard/cubit/dashboard_cubit.dart';
import 'package:gp1/presentation/dashboard/widgets/device_control_card.dart';
import 'package:gp1/presentation/dashboard/widgets/sensor_chart.dart';
import 'package:gp1/presentation/dashboard/widgets/sensor_stat_card.dart';
import 'package:gp1/presentation/sensors/models/sensor_series.dart';
import 'package:gp1/presentation/widgets/my_app_bar.dart';

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
          return const Center(child: CircularProgressIndicator());
        }

        final temperature = state.series.of(SensorType.temperature);
        final humidity = state.series.of(SensorType.humidity);
        final light = state.series.of(SensorType.light);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 800;

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
                    isWide: isWide,
                    children: [
                      SensorStatCard(
                        title: 'Temperature',
                        value: '${temperature.latestValue}',
                        unit: '°C',
                        icon: Icons.thermostat,
                        color: const Color(0xFFFF6063),
                        trend: temperature.trend,
                      ),
                      SensorStatCard(
                        title: 'Humidity',
                        value: '${humidity.latestValue}',
                        unit: '%',
                        icon: Icons.water_drop,
                        color: const Color(0xFF33A0FF),
                        trend: humidity.trend,
                      ),
                      SensorStatCard(
                        title: 'Light',
                        value: '${light.latestValue}',
                        unit: 'lux',
                        icon: Icons.light_mode,
                        color: const Color(0xFFFFD633),
                        trend: light.trend,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Section Title: Today's Charts ──
                  const _SectionTitle(title: "Today's Trend", icon: Icons.show_chart),
                  const SizedBox(height: 12),

                  // ── Charts ──
                  _ResponsiveGrid(
                    isWide: isWide,
                    children: [
                      SensorChart(
                        title: 'Temperature',
                        unit: '°C',
                        color: const Color(0xFFFF6063),
                        dataPoints: _todaySpots(temperature),
                      ),
                      SensorChart(
                        title: 'Humidity',
                        unit: '%',
                        color: const Color(0xFF33A0FF),
                        dataPoints: _todaySpots(humidity),
                      ),
                      SensorChart(
                        title: 'Light',
                        unit: 'lux',
                        color: const Color(0xFFFFD633),
                        dataPoints: _todaySpots(light),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Section Title: Device Controls ──
                  const _SectionTitle(title: 'Device Controls', icon: Icons.toggle_on),
                  const SizedBox(height: 12),

                  // ── Device Control Cards ──
                  _ResponsiveGrid(
                    isWide: isWide,
                    children: [
                      DeviceControlCard(
                        title: 'LED',
                        subtitle: 'Smart lighting control',
                        icon: Icons.light_mode,
                        color: const Color(0xFFFFD633),
                        isOn: state.isLedOn,
                        onToggle: context.read<DashboardCubit>().setLedOn,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Chart x-axis is the hour of day (e.g. 13.5 = 13:30).
  static List<FlSpot> _todaySpots(SensorSeries series) {
    return series.readings
        .map((r) => FlSpot(r.timestamp.hour + r.timestamp.minute / 60.0, r.value))
        .toList();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: const Color(0xFF0483CA)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF191919),
          ),
        ),
      ],
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({required this.isWide, required this.children});
  final bool isWide;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children
            .map(
              (child) => Expanded(
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: child),
              ),
            )
            .toList(),
      );
    }
    return Column(
      children: children
          .map((child) => Padding(padding: const EdgeInsets.only(bottom: 12), child: child))
          .toList(),
    );
  }
}
