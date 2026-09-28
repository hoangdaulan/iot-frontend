import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gp1/app/navigation/app_route.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/widgets/app_logo.dart';
import 'package:gp1/presentation/widgets/developer_attribution.dart';
import 'package:solar_icons/solar_icons.dart';

class WebLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  WebLayout({super.key, required this.navigationShell});

  final allItems = AppRoute.all;

  void _onTabTapped(AppRoute item) {
    final index = allItems.indexOf(item);
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final isMobile = maxWidth < 640;
        final isDesktop = maxWidth >= 960;
        return Scaffold(
          appBar: _IoTAppBar(
            onProfilePressed: () => _onTabTapped(AppRoute.account),
          ),
          drawer: isMobile
              ? _MobileDrawer(
                  selectedItem: allItems[navigationShell.currentIndex],
                  onTabTapped: _onTabTapped,
                )
              : null,
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile) ...[
                  _NavigationSideBar(
                    isDesktop: isDesktop,
                    selectedItem: allItems[navigationShell.currentIndex],
                    onTabTapped: _onTabTapped,
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                ],
                Expanded(child: navigationShell),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IoTAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _IoTAppBar({required this.onProfilePressed});
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          const AppLogo(width: 32, height: 32),
          const SizedBox(width: 10),
          const Text(
            'IoT Dashboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: ColorName.primary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onProfilePressed,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ColorName.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(SolarIconsOutline.user, size: 20, color: ColorName.primary),
            ),
          ),
        ],
      ),
      bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1.0)),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({
    required this.selectedItem,
    required this.onTabTapped,
  });

  final AppRoute selectedItem;
  final Function(AppRoute item) onTabTapped;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: _NavigationSideBar(
        isMobile: true,
        selectedItem: selectedItem,
        onTabTapped: (item) {
          onTabTapped(item);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _NavigationSideBar extends StatefulWidget {
  const _NavigationSideBar({
    this.isMobile = false,
    this.isDesktop = false,
    required this.selectedItem,
    required this.onTabTapped,
  });

  final bool isMobile;
  final bool isDesktop;
  final AppRoute selectedItem;
  final Function(AppRoute item) onTabTapped;

  @override
  State<_NavigationSideBar> createState() => _NavigationSideBarState();
}

class _NavigationSideBarState extends State<_NavigationSideBar> {
  late bool isExpanded;

  final double expandedWidth = 200;
  final double collapsedWidth = 72;

  @override
  void initState() {
    super.initState();
    isExpanded = widget.isDesktop || widget.isMobile;
  }

  @override
  void didUpdateWidget(covariant _NavigationSideBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDesktop != widget.isDesktop || oldWidget.isMobile != widget.isMobile) {
      isExpanded = widget.isDesktop || widget.isMobile;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = AppRoute.all;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isExpanded ? expandedWidth : collapsedWidth,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    if (!widget.isMobile)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: ColorName.gray5),
                        ),
                        child: InkWell(
                          onTap: () => setState(() => isExpanded = !isExpanded),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isExpanded) ...[
                                  const Expanded(
                                    child: Text(
                                      'Collapse',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: ColorName.labelSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                Icon(
                                  isExpanded
                                      ? SolarIconsOutline.sendSquare
                                      : SolarIconsOutline.receiveSquare,
                                  color: ColorName.labelSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    for (final item in items)
                      Builder(
                        builder: (context) {
                          final isSelected = widget.selectedItem == item;
                          return InkWell(
                            onTap: () => widget.onTabTapped(item),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ColorName.primary.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: isExpanded
                                    ? MainAxisAlignment.start
                                    : MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSelected ? item.selectedIcon : item.icon,
                                    color: isSelected ? ColorName.primary : ColorName.labelSecondary,
                                    size: 22,
                                  ),
                                  if (isExpanded) ...[
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          color: isSelected
                                              ? ColorName.primary
                                              : ColorName.labelPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          const DeveloperAttribution(fontSize: 13),
        ],
      ),
    );
  }
}
