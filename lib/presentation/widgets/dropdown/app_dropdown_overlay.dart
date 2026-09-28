import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gp1/core/ui/go_dropdown/go_dropdown.dart';
import 'package:gp1/presentation/widgets/app_loading.dart';
import 'package:gp1/presentation/widgets/dropdown/app_dropdown_search_type.dart';
import 'package:gp1/presentation/widgets/dropdown/app_dropdown_type.dart';

export 'package:gp1/presentation/widgets/dropdown/app_dropdown_search_type.dart';
export 'package:gp1/presentation/widgets/dropdown/app_dropdown_type.dart';

class AppDropdownOverlay<T> extends StatelessWidget {
  final AppDropdownType _type;
  final AppDropdownSearchType searchType;

  final VoidCallback hideOverlay;

  final FutureOr<List<T>> Function(String) items;
  final T? selectedItem;
  final List<T> selectedItems;

  final String? labelText;

  final Function(T?)? onChanged;
  final Function(List<T>)? onListChanged;

  final Widget? additionalOverlayHeader;
  final double? overlayHeight;

  const AppDropdownOverlay.single({
    super.key,
    required this.hideOverlay,
    this.searchType = AppDropdownSearchType.search,
    required this.items,
    this.selectedItem,
    this.labelText,
    this.onChanged,
    this.additionalOverlayHeader,
    this.overlayHeight,
  }) : _type = AppDropdownType.single,
       selectedItems = const [],
       onListChanged = null;

  const AppDropdownOverlay.multiple({
    super.key,
    required this.hideOverlay,
    this.searchType = AppDropdownSearchType.search,
    required this.items,
    this.selectedItems = const [],
    this.labelText,
    this.onListChanged,
    this.additionalOverlayHeader,
    this.overlayHeight,
  }) : _type = AppDropdownType.multiple,
       selectedItem = null,
       onChanged = null;

  Widget _buildOverlayHeader(BuildContext context, VoidCallback hideOverlay) {
    return Column(
      spacing: 4,
      children: [
        GestureDetector(
          onTap: hideOverlay,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    labelText ?? '',
                    style: Theme.of(context).inputDecorationTheme.hintStyle,
                  ),
                ),
                const Icon(Icons.close, size: 18),
              ],
            ),
          ),
        ),
        ?additionalOverlayHeader,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final showSearch = searchType != AppDropdownSearchType.none;
    final delay = searchType == AppDropdownSearchType.debounceSearch
        ? const Duration(milliseconds: 500)
        : Duration.zero;

    final noResultFoundText = 'Không tìm thấy kết quả';
    final loadingIndicator = const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: AppLoading(size: 24),
    );

    return GoDropdownOverlay<T>(
      hideOverlay: hideOverlay,
      type: _type == AppDropdownType.single ? DropdownType.single : DropdownType.multiple,
      items: items,
      selectedItem: selectedItem,
      selectedItems: selectedItems,
      hideOnSelect: false,
      showSearch: showSearch,
      requestDelay: delay,
      labelText: labelText,
      noResultFoundText: noResultFoundText,
      onChanged: onChanged,
      onListChanged: onListChanged,
      overlayHeader: _buildOverlayHeader,
      loadingIndicator: loadingIndicator,
      overlayHeight: overlayHeight,
    );
  }
}
