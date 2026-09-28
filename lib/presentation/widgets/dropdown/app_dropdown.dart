import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gp1/core/ui/go_dropdown/go_dropdown.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/widgets/app_loading.dart';
import 'package:gp1/presentation/widgets/dropdown/app_dropdown_search_type.dart';
import 'package:gp1/presentation/widgets/dropdown/app_dropdown_type.dart';
import 'package:gp1/presentation/widgets/models/app_field_style.dart';
import 'package:solar_icons/solar_icons.dart';

export 'package:gp1/presentation/widgets/dropdown/app_dropdown_search_type.dart';
export 'package:gp1/presentation/widgets/dropdown/app_dropdown_type.dart';

class AppDropdown<T> extends StatelessWidget {
  final AppDropdownType _type;
  final AppDropdownSearchType searchType;
  final AppFieldStyle style;

  final FutureOr<List<T>> Function(String) items;
  final T? selectedItem;
  final List<T> selectedItems;

  final String? labelText;
  final String? hintText;
  final InputDecoration? decoration;

  final Function(T?)? onChanged;
  final Function(List<T>)? onListChanged;

  final String? Function(T?)? validator;
  final String? Function(List<T>)? listValidator;

  final Widget? additionalOverlayHeader;

  const AppDropdown.single({
    super.key,
    this.searchType = AppDropdownSearchType.search,
    this.style = AppFieldStyle.normal,
    required this.items,
    this.selectedItem,
    this.labelText,
    this.hintText,
    this.decoration,
    this.onChanged,
    this.validator,
    this.additionalOverlayHeader,
  }) : assert(
         decoration == null || (labelText == null && hintText == null),
         'Cannot provide both decoration and labelText/hintText. '
         'When providing decoration, please set labelText/hintText inside decoration instead.',
       ),
       _type = AppDropdownType.single,
       selectedItems = const [],
       onListChanged = null,
       listValidator = null;

  const AppDropdown.multiple({
    super.key,
    this.searchType = AppDropdownSearchType.search,
    this.style = AppFieldStyle.normal,
    required this.items,
    this.selectedItems = const [],
    this.labelText,
    this.hintText,
    this.decoration,
    this.onListChanged,
    this.listValidator,
    this.additionalOverlayHeader,
  }) : assert(
         decoration == null || (labelText == null && hintText == null),
         'Cannot provide both decoration and labelText/hintText. '
         'When providing decoration, please set labelText/hintText inside decoration instead.',
       ),
       _type = AppDropdownType.multiple,
       selectedItem = null,
       onChanged = null,
       validator = null;

  InputDecoration get _inputDecoration {
    final inputDecoration =
        decoration ??
        InputDecoration(
          labelText: labelText,
          hintText: hintText,
          suffixIcon: const Padding(
            padding: EdgeInsetsDirectional.only(end: 12.0),
            child: Icon(SolarIconsOutline.altArrowDown, size: 18),
          ),
        );
    return style.getInputDecoration(base: inputDecoration);
  }

  Widget _buildOverlayHeader(BuildContext context, VoidCallback hideOverlay) {
    return Column(
      spacing: 4,
      children: [
        GestureDetector(
          onTap: hideOverlay,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    labelText ?? hintText ?? '',
                    style: Theme.of(context).inputDecorationTheme.hintStyle,
                  ),
                ),
                const Icon(SolarIconsOutline.altArrowUp, size: 18),
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
    final overlayDecoration = BoxDecoration(
      color: ColorName.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          blurRadius: 8,
          color: Colors.black.withValues(alpha: 0.1),
          offset: const Offset(0, 4),
        ),
      ],
    );

    final showSearch = searchType != AppDropdownSearchType.none;
    final delay = searchType == AppDropdownSearchType.debounceSearch
        ? const Duration(milliseconds: 500)
        : Duration.zero;

    final noResultFoundText = 'Không tìm thấy kết quả';
    final loadingIndicator = const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: AppLoading(size: 24),
    );

    if (_type == AppDropdownType.single) {
      return GoDropdown<T>.single(
        items: items,
        selectedItem: selectedItem,
        showSearch: showSearch,
        requestDelay: delay,
        labelText: labelText,
        hintText: hintText,
        onChanged: onChanged,
        validator: validator,
        overlayHeader: _buildOverlayHeader,
        decoration: _inputDecoration,
        overlayDecoration: overlayDecoration,
        noResultFoundText: noResultFoundText,
        loadingIndicator: loadingIndicator,
      );
    } else {
      return GoDropdown<T>.multiple(
        items: items,
        selectedItems: selectedItems,
        showSearch: showSearch,
        requestDelay: delay,
        labelText: labelText,
        hintText: hintText,
        onListChanged: onListChanged,
        listValidator: listValidator,
        overlayHeader: _buildOverlayHeader,
        decoration: _inputDecoration,
        overlayDecoration: overlayDecoration,
        noResultFoundText: noResultFoundText,
        loadingIndicator: loadingIndicator,
      );
    }
  }
}
