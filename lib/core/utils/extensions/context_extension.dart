import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  Future<T?> showRequiredDialog<T>({required Widget child}) {
    return showDialog<T>(
      context: this,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) {
        return PopScope(canPop: false, child: child);
      },
    );
  }
}
