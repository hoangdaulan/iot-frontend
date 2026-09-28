import 'package:flutter/material.dart';

enum AppFieldStyle {
  normal,
  normalCompact,
  noBorder,
  noBorderCompact;

  InputDecoration getInputDecoration({InputDecoration? base}) {
    final InputDecoration decoration = base ?? const InputDecoration();

    final border = this == AppFieldStyle.noBorder || this == AppFieldStyle.noBorderCompact
        ? InputBorder.none
        : null;

    final padding = switch (this) {
      AppFieldStyle.normal => null,
      AppFieldStyle.normalCompact => const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      AppFieldStyle.noBorder => const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      AppFieldStyle.noBorderCompact => const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
    };

    final isDense = this == AppFieldStyle.normalCompact || this == AppFieldStyle.noBorderCompact;

    return decoration.copyWith(
      isDense: isDense,
      visualDensity: isDense ? VisualDensity.compact : null,
      contentPadding: padding,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      focusedErrorBorder: border,
      errorBorder: border,
    );
  }
}
