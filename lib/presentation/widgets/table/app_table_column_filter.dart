import 'package:flutter/material.dart';

export 'package:gp1/presentation/widgets/table/table_dropdown_filter.dart';
export 'package:gp1/presentation/widgets/table/table_search_filter.dart';

abstract class AppTableColumnFilter<T> {
  const AppTableColumnFilter();

  bool get isActive;
  Widget overlay(BuildContext context, VoidCallback hideOverlay);
}
