import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gp1/presentation/widgets/dropdown/app_dropdown_overlay.dart';
import 'package:gp1/presentation/widgets/table/app_table_column_filter.dart';
import 'package:gp1/presentation/widgets/table/table_filter_action.dart';

class TableDropdownFilter<T> extends AppTableColumnFilter<T> {
  final AppDropdownType _type;
  final AppDropdownSearchType searchType;

  final FutureOr<List<T>> Function(String) items;
  final T? selectedItem;
  final List<T> selectedItems;

  final String? labelText;

  final Function(T?)? onChanged;
  final Function(List<T>)? onListChanged;

  const TableDropdownFilter.single({
    this.searchType = AppDropdownSearchType.search,
    required this.items,
    this.selectedItem,
    this.labelText,
    this.onChanged,
  }) : _type = AppDropdownType.single,
       selectedItems = const [],
       onListChanged = null;

  const TableDropdownFilter.multiple({
    this.searchType = AppDropdownSearchType.search,
    required this.items,
    this.selectedItems = const [],
    this.labelText,
    this.onListChanged,
  }) : _type = AppDropdownType.multiple,
       selectedItem = null,
       onChanged = null;

  @override
  bool get isActive => switch (_type) {
    AppDropdownType.single => selectedItem != null,
    AppDropdownType.multiple => selectedItems.isNotEmpty,
  };

  @override
  Widget overlay(BuildContext context, VoidCallback hideOverlay) {
    return _TableDropdownFilterContent<T>(
      hideOverlay: hideOverlay,
      type: _type,
      searchType: searchType,
      items: items,
      selectedItem: selectedItem,
      selectedItems: selectedItems,
      labelText: labelText,
      onChanged: onChanged,
      onListChanged: onListChanged,
    );
  }
}

class _TableDropdownFilterContent<T> extends StatefulWidget {
  const _TableDropdownFilterContent({
    required this.hideOverlay,
    required this.type,
    required this.searchType,
    required this.items,
    this.selectedItem,
    this.selectedItems = const [],
    this.labelText,
    this.onChanged,
    this.onListChanged,
  });

  final VoidCallback hideOverlay;

  final AppDropdownType type;
  final AppDropdownSearchType searchType;

  final FutureOr<List<T>> Function(String) items;
  final T? selectedItem;
  final List<T> selectedItems;

  final String? labelText;

  final Function(T?)? onChanged;
  final Function(List<T>)? onListChanged;

  @override
  State<_TableDropdownFilterContent<T>> createState() => __TableDropdownFilterContentState();
}

class __TableDropdownFilterContentState<T> extends State<_TableDropdownFilterContent<T>> {
  T? selectedItem;
  List<T> selectedItems = [];

  @override
  void initState() {
    super.initState();
    selectedItem = widget.selectedItem;
    selectedItems = widget.selectedItems;
  }

  void _onChanged(T? value) {
    setState(() => selectedItem = value);
  }

  void _onListChanged(List<T> value) {
    setState(() => selectedItems = value);
  }

  bool get _hasSelected => switch (widget.type) {
    AppDropdownType.single => widget.selectedItem != null,
    AppDropdownType.multiple => widget.selectedItems.isNotEmpty,
  };

  void _onClear() {
    switch (widget.type) {
      case AppDropdownType.single:
        widget.onChanged?.call(null);
      case AppDropdownType.multiple:
        widget.onListChanged?.call([]);
    }
    widget.hideOverlay();
  }

  bool get _isChanged {
    switch (widget.type) {
      case AppDropdownType.single:
        return selectedItem != widget.selectedItem;
      case AppDropdownType.multiple:
        return selectedItems != widget.selectedItems;
    }
  }

  void _onApply() {
    switch (widget.type) {
      case AppDropdownType.single:
        widget.onChanged?.call(selectedItem);
      case AppDropdownType.multiple:
        widget.onListChanged?.call(selectedItems);
    }
    widget.hideOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        switch (widget.type) {
          AppDropdownType.single => AppDropdownOverlay<T>.single(
            hideOverlay: widget.hideOverlay,
            searchType: widget.searchType,
            items: widget.items,
            selectedItem: selectedItem,
            labelText: widget.labelText,
            onChanged: _onChanged,
          ),
          AppDropdownType.multiple => AppDropdownOverlay<T>.multiple(
            hideOverlay: widget.hideOverlay,
            searchType: widget.searchType,
            items: widget.items,
            selectedItems: selectedItems,
            labelText: widget.labelText,
            onListChanged: _onListChanged,
          ),
        },
        const Divider(),
        TableFilterAction(
          onClear: _hasSelected ? _onClear : null,
          onCancel: widget.hideOverlay,
          onApply: _isChanged ? _onApply : null,
        ),
      ],
    );
  }
}
