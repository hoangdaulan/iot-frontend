import 'package:flutter/material.dart';

class AppTableSelectConfig<T> {
  final List<T> selectedItems;
  final void Function(T item) onRowSelected;
  final VoidCallback onSelectAll;
  final List<Widget>? actions;

  const AppTableSelectConfig({
    required this.selectedItems,
    required this.onRowSelected,
    required this.onSelectAll,
    this.actions,
  });
}
