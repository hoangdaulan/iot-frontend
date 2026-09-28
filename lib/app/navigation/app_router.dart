import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gp1/app/navigation/app_route.dart';
import 'package:gp1/app/navigation/e_app_route.dart';
import 'package:gp1/core/auth/auth_notifier.dart';
import 'package:gp1/core/di/injection.dart';
import 'package:gp1/presentation/app/widgets/mobile_layout.dart';
import 'package:gp1/presentation/app/widgets/web_layout.dart';

class AppRouter {
  static final rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _authNotifier = getIt<AuthNotifier>();

  static final router = GoRouter(
    debugLogDiagnostics: kDebugMode,
    navigatorKey: rootNavigatorKey,
    initialLocation: EAppRoute.dashboard.path,
    refreshListenable: _authNotifier,
    redirect: _redirect,
    routes: _routes,
  );

  static List<RouteBase> get _routes {
    final webShellBranches = AppRoute.all.map((e) => e.shellBranch).toList();
    final mobileShellBranches = AppRoute.mobileShellRoutes.map((e) => e.shellBranch).toList();
    final mobileOtherRoutes = AppRoute.all
        .where((route) => !AppRoute.mobileShellRoutes.contains(route))
        .toList();

    return [
      ...AppRoute.base,

      if (kIsWeb)
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => WebLayout(navigationShell: navigationShell),
          branches: webShellBranches,
        )
      else ...[
        ...mobileOtherRoutes,
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              MobileLayout(navigationShell: navigationShell),
          branches: mobileShellBranches,
        ),
      ],
    ];
  }

  static String? _redirect(BuildContext context, GoRouterState state) {
    final isPublicPath = publicPaths.contains(state.uri.path);
    final isAuthenticated = _authNotifier.isAuthenticated;

    if (!isAuthenticated && !isPublicPath) {
      return EAppRoute.login.path;
    }

    if (isAuthenticated && isPublicPath) {
      return EAppRoute.dashboard.path;
    }

    return null;
  }
}

extension on RouteBase {
  StatefulShellBranch get shellBranch => StatefulShellBranch(routes: [this]);
}
