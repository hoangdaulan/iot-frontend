import 'package:flutter/material.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:solar_icons/solar_icons.dart';

enum SnackBarType {
  success,
  info,
  warning,
  error;

  Color get color => switch (this) {
    SnackBarType.success => ColorName.green,
    SnackBarType.info => ColorName.blue,
    SnackBarType.warning => ColorName.orange,
    SnackBarType.error => ColorName.red,
  };

  IconData get icon => switch (this) {
    SnackBarType.success => SolarIconsOutline.checkCircle,
    SnackBarType.info => SolarIconsOutline.dangerCircle,
    SnackBarType.warning => SolarIconsOutline.dangerTriangle,
    SnackBarType.error => SolarIconsOutline.danger,
  };
}

extension SnackBarExtension on BuildContext {
  void showSnackBar(String message, {SnackBarType type = SnackBarType.info}) {
    ScaffoldMessenger.of(this).clearSnackBars();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Row(
          spacing: 8,
          children: [
            Icon(type.icon, color: ColorName.white),
            Expanded(child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis)),
          ],
        ),
        backgroundColor: type.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void handleFailure(Failure? failure) {
    if (failure != null) {
      showSnackBar(failure.message ?? 'Đã xảy ra lỗi.', type: SnackBarType.error);
    }
  }
}
