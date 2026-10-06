import 'package:flutter/material.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/widgets/app_info_chip.dart';

class DeviceControlCard extends StatelessWidget {
  const DeviceControlCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isOn,
    required this.onToggle,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isOn;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOn ? color.withValues(alpha: 0.06) : ColorName.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOn ? color.withValues(alpha: 0.3) : ColorName.gray5),
        boxShadow: [
          BoxShadow(
            color: (isOn ? color : Colors.black).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isOn ? color.withValues(alpha: 0.15) : ColorName.gray6,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isOn ? color : ColorName.labelSecondary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorName.labelPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: ColorName.labelSecondary),
                ),
                const SizedBox(height: 6),
                AppInfoChip(
                  label: isOn ? 'Active' : 'Inactive',
                  color: isOn ? ColorName.green : ColorName.labelSecondary,
                ),
              ],
            ),
          ),
          Switch.adaptive(value: isOn, onChanged: onToggle, activeTrackColor: color),
        ],
      ),
    );
  }
}
