import 'package:flutter/material.dart';
import 'package:gp1/app/constants/app_breakpoints.dart';

class ResponsiveItem {
  final Widget child;
  final int? flex;
  final double? width;
  final EdgeInsetsGeometry? padding;

  const ResponsiveItem({required this.child, this.flex, this.width, this.padding})
    : assert(flex == null || width == null, 'Cannot provide both flex and width. Choose one.');
}

class ResponsiveLayout extends StatelessWidget {
  final List<ResponsiveItem> items;
  final double breakpoint;
  final double spacing;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool intrinsicHeight;

  const ResponsiveLayout({
    super.key,
    required this.items,
    this.breakpoint = AppBreakpoints.desktopBreakpoint,
    this.spacing = 0,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.intrinsicHeight = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= breakpoint;
        if (isWide && intrinsicHeight) {
          return IntrinsicHeight(child: _buildBody(isWide));
        }
        return _buildBody(isWide);
      },
    );
  }

  Flex _buildBody(bool isWide) {
    return Flex(
      spacing: spacing,
      direction: isWide ? Axis.horizontal : Axis.vertical,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: isWide ? crossAxisAlignment : CrossAxisAlignment.stretch,
      children: items.map((item) {
        final child = Padding(padding: item.padding ?? EdgeInsets.zero, child: item.child);

        if (isWide) {
          if (item.width != null) {
            return SizedBox(width: item.width, child: child);
          }
          if (item.flex != null) {
            return Expanded(flex: item.flex!, child: child);
          }
        }
        return child;
      }).toList(),
    );
  }
}
