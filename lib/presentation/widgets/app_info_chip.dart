import 'package:flutter/material.dart';
import 'package:gp1/generated/colors.gen.dart';

enum EAppInfoChipSize { small, medium }

class AppInfoChip extends StatelessWidget {
  const AppInfoChip({
    super.key,
    this.size = EAppInfoChipSize.small,
    required this.label,
    this.icon,
    this.color = ColorName.labelSecondary,
  });

  final EAppInfoChipSize size;
  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final padding = size == EAppInfoChipSize.small
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 4);

    final radius = size == EAppInfoChipSize.small ? 4.0 : 8.0;

    final fontSize = size == EAppInfoChipSize.small ? 12.0 : 14.0;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        spacing: 4,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: fontSize, color: color),
          Text(
            label,
            style: TextStyle(color: color, fontSize: fontSize),
          ),
        ],
      ),
    );
  }
}
