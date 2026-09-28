import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gp1/app/navigation/app_route.dart';

class MobileLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MobileLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final visibleRoutes = AppRoute.mobileShellRoutes;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: visibleRoutes.map((item) {
          return NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: item.shortTitle ?? item.title,
          );
        }).toList(),
      ),
    );
  }
}
