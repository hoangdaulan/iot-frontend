import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/presentation/dashboard/cubit/dashboard_cubit.dart';
import 'package:gp1/presentation/dashboard/widgets/device_control_card.dart';
import 'package:gp1/presentation/dashboard/widgets/sensor_chart.dart';
import 'package:gp1/presentation/dashboard/widgets/sensor_stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DashboardCubit()..loadDashboard(),
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

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
                        value: '${state.currentTemperature}',
                        unit: '°C',
                        icon: Icons.thermostat,
                        color: const Color(0xFFFF6063),
                        trend: state.temperatureTrend,
                      ),
                      SensorStatCard(
                        title: 'Humidity',
                        value: '${state.currentHumidity}',
                        unit: '%',
                        icon: Icons.water_drop,
                        color: const Color(0xFF33A0FF),
                        trend: state.humidityTrend,
                      ),
                      SensorStatCard(
                        title: 'Light',
                        value: '${state.currentLight}',
                        unit: 'lux',
                        icon: Icons.light_mode,
                        color: const Color(0xFFFFD633),
                        trend: state.lightTrend,
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
                        dataPoints: state.temperatureChartData,
                      ),
                      SensorChart(
                        title: 'Humidity',
                        unit: '%',
                        color: const Color(0xFF33A0FF),
                        dataPoints: state.humidityChartData,
                      ),
                      SensorChart(
                        title: 'Light',
                        unit: 'lux',
                        color: const Color(0xFFFFD633),
                        dataPoints: state.lightChartData,
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
                        title: 'Temperature Sensor',
                        subtitle: 'Auto-regulate HVAC system',
                        icon: Icons.thermostat,
                        color: const Color(0xFFFF6063),
                        isOn: state.temperatureSensorOn,
                        onToggle: (value) => context.read<DashboardCubit>().toggleDevice('temperature'),
                      ),
                      DeviceControlCard(
                        title: 'Humidity Sensor',
                        subtitle: 'Control humidifier',
                        icon: Icons.water_drop,
                        color: const Color(0xFF33A0FF),
                        isOn: state.humiditySensorOn,
                        onToggle: (value) => context.read<DashboardCubit>().toggleDevice('humidity'),
                      ),
                      DeviceControlCard(
                        title: 'Light Sensor',
                        subtitle: 'Smart lighting control',
                        icon: Icons.light_mode,
                        color: const Color(0xFFFFD633),
                        isOn: state.lightSensorOn,
                        onToggle: (value) => context.read<DashboardCubit>().toggleDevice('light'),
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
            .map((child) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: child,
                  ),
                ))
            .toList(),
      );
    }
    return Column(
      children: children
          .map((child) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: child,
              ))
          .toList(),
    );
  }
}
