import 'package:flutter/material.dart';

extension WidgetListSeparator on List<Widget> {
  List<Widget> separatedBy(Widget separator) {
    if (isEmpty) return [];

    return [
      first,
      for (final widget in skip(1)) ...[
        separator,
        widget,
      ],
    ];
  }
}