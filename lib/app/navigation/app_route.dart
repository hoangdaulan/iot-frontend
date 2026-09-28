import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gp1/app/navigation/e_app_route.dart';
import 'package:gp1/core/di/injection.dart';
import 'package:gp1/presentation/auth/login_screen.dart';
import 'package:gp1/presentation/change_password/change_password_screen.dart';
import 'package:gp1/presentation/control_history/control_history_screen.dart';
import 'package:gp1/presentation/dashboard/dashboard_screen.dart';
import 'package:gp1/presentation/profile/profile_screen.dart';
import 'package:gp1/presentation/sensors/sensors_screen.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AppRoute extends GoRoute {
  final String title;
  final String? shortTitle;
  final IconData icon;
  final IconData selectedIcon;

  AppRoute({
    required this.title,
    this.shortTitle,
    this.icon = SolarIconsOutline.codeSquare,
    this.selectedIcon = SolarIconsBold.codeSquare,

    required super.path,
    super.builder,
    super.routes,
  });

  static final base = [login, log];
  static final all = [
    dashboard,
    sensors,
    controlHistory,
    account,
  ];
  static final mobileShellRoutes = [dashboard, sensors, controlHistory, account];

  static final login = AppRoute(
    title: 'Login',
    path: EAppRoute.login.path,
    builder: (context, state) => const LoginScreen(),
  );

  static final log = AppRoute(
    title: 'Log',
    path: EAppRoute.log.path,
    builder: (context, state) => TalkerScreen(talker: getIt<Talker>()),
  );

  static final dashboard = AppRoute(
    title: 'Dashboard',
    icon: SolarIconsOutline.widget_4,
    selectedIcon: SolarIconsBold.widget_4,
    path: EAppRoute.dashboard.path,
    builder: (context, state) => const DashboardScreen(),
  );

  static final sensors = AppRoute(
    title: 'Sensors',
    icon: SolarIconsOutline.temperature,
    selectedIcon: SolarIconsBold.temperature,
    path: EAppRoute.sensors.path,
    builder: (context, state) => const SensorsScreen(),
  );

  static final controlHistory = AppRoute(
    title: 'Control History',
    shortTitle: 'Control',
    icon: SolarIconsOutline.history,
    selectedIcon: SolarIconsBold.history,
    path: EAppRoute.controlHistory.path,
    builder: (context, state) => const ControlHistoryScreen(),
  );

  static final account = AppRoute(
    title: 'Account',
    icon: SolarIconsOutline.user,
    selectedIcon: SolarIconsBold.user,
    path: EAppRoute.account.path,
    builder: (context, state) => const ProfileScreen(),
    routes: [
      GoRoute(
        path: EAppRoute.changePassword.path,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
    ],
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppRoute && runtimeType == other.runtimeType && path == other.path;

  @override
  int get hashCode => path.hashCode;
}
