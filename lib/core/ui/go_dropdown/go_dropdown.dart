import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gp1/core/ui/animated_overlay/animated_overlay.dart';

mixin GoDropdownDisplayText {
  String get displayText;
}

String _getDisplayText(Object? item) {
  if (item == null) return '';
  if (item is GoDropdownDisplayText) {
    return item.displayText;
  }
  return item.toString();
}

enum DropdownType { single, multiple }

class GoDropdown<T> extends StatelessWidget {
  final DropdownType _type;

  final FutureOr<List<T>> Function(String) items;
  final T? selectedItem;
  final List<T> selectedItems;

  final bool showSearch;
  final Duration requestDelay;

  final String? labelText;
  final String? hintText;
  final String noResultFoundText;

  final Function(T?)? onChanged;
  final Function(List<T>)? onListChanged;

  final String Function(T? selectedItem)? headerText;
  final String Function(List<T> selectedItems)? headerListText;
  final Widget Function(BuildContext context, T item, bool isSelected)? listItemBuilder;

  final String? Function(T?)? validator;
  final String? Function(List<T>)? listValidator;

  final Widget Function(BuildContext context, VoidCallback hideOverlay)? overlayHeader;
  final Widget? loadingIndicator;

  final double? overlayHeight;
  final InputDecoration? decoration;
  final BoxDecoration? overlayDecoration;

  final double overlayPaddingBottom;
  final AnimatedOverlayDirection direction;

  const GoDropdown.single({
    super.key,
    required this.items,
    this.selectedItem,
    this.showSearch = false,
    this.requestDelay = Duration.zero,
    this.labelText,
    this.hintText,
    this.noResultFoundText = 'No results found',
    this.onChanged,
    this.headerText,
    this.listItemBuilder,
    this.validator,
    this.overlayHeader,
    this.loadingIndicator,
    this.overlayHeight,
    this.decoration,
    this.overlayDecoration,
    this.overlayPaddingBottom = 0.0,
    this.direction = AnimatedOverlayDirection.auto,
  }) : _type = DropdownType.single,
       selectedItems = const [],
       onListChanged = null,
       headerListText = null,
       listValidator = null;

  const GoDropdown.multiple({
    super.key,
    required this.items,
    this.selectedItems = const [],
    this.showSearch = false,
    this.requestDelay = Duration.zero,
    this.labelText,
    this.hintText,
    this.noResultFoundText = 'No results found',
    this.onListChanged,
    this.headerListText,
    this.listItemBuilder,
    this.listValidator,
    this.overlayHeader,
    this.loadingIndicator,
    this.overlayHeight,
    this.decoration,
    this.overlayDecoration,
    this.overlayPaddingBottom = 0.0,
    this.direction = AnimatedOverlayDirection.auto,
  }) : _type = DropdownType.multiple,
       selectedItem = null,
       onChanged = null,
       headerText = null,
       validator = null;

  @override
  Widget build(BuildContext context) {
    return AnimatedOverlay(
      overlayPaddingBottom: overlayPaddingBottom,
      overlayDecoration: overlayDecoration,
      direction: direction,
      overlay: (hideOverlay) {
        return GoDropdownOverlay<T>(
          hideOverlay: hideOverlay,
          type: _type,
          items: items,
          selectedItem: selectedItem,
          selectedItems: selectedItems,
          hideOnSelect: true,
          showSearch: showSearch,
          requestDelay: requestDelay,
          labelText: labelText,
          hintText: hintText,
          noResultFoundText: noResultFoundText,
          onChanged: onChanged,
          onListChanged: onListChanged,
          listItemBuilder: listItemBuilder,
          overlayHeader: overlayHeader,
          loadingIndicator: loadingIndicator,
          overlayHeight: overlayHeight,
        );
      },
      child: (showOverlay) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: showOverlay,
          child: IgnorePointer(
            child: TextFormField(
              controller: TextEditingController(
                text: _type == DropdownType.single
                    ? headerText?.call(selectedItem) ?? _getDisplayText(selectedItem)
                    : headerListText?.call(selectedItems) ??
                          selectedItems.map(_getDisplayText).join(', '),
              ),
              readOnly: true,
              decoration:
                  decoration ??
                  InputDecoration(
                    labelText: labelText,
                    hintText: hintText,
                    suffixIcon: const Padding(
                      padding: EdgeInsetsDirectional.only(end: 12.0),
                      child: Icon(Icons.arrow_drop_down),
                    ),
                  ),
              validator: (_) => _type == DropdownType.single
                  ? validator?.call(selectedItem)
                  : listValidator?.call(selectedItems),
            ),
          ),
        );
      },
    );
  }
}

class GoDropdownOverlay<T> extends StatefulWidget {
  const GoDropdownOverlay({
    super.key,
    required this.hideOverlay,
    required this.type,
    required this.items,
    this.selectedItem,
    this.selectedItems = const [],
    this.query,
    this.hideOnSelect = true,
    this.showSearch = false,
    this.requestDelay = Duration.zero,
    this.labelText,
    this.hintText,
    this.noResultFoundText = 'No results found',
    this.onChanged,
    this.onListChanged,
    this.listItemBuilder,
    this.overlayHeader,
    this.loadingIndicator,
    this.overlayHeight,
  });

  final VoidCallback hideOverlay;
  final DropdownType type;

  final FutureOr<List<T>> Function(String) items;
  final T? selectedItem;
  final List<T> selectedItems;
  final String? query;

  final bool hideOnSelect;
  final bool showSearch;
  final Duration requestDelay;

  final String? labelText;
  final String? hintText;
  final String noResultFoundText;

  final Function(T?)? onChanged;
  final Function(List<T>)? onListChanged;

  final Widget Function(BuildContext context, T item, bool isSelected)? listItemBuilder;

  final Widget Function(BuildContext context, VoidCallback hideOverlay)? overlayHeader;
  final Widget? loadingIndicator;
  final double? overlayHeight;

  @override
  State<GoDropdownOverlay<T>> createState() => _GoDropdownOverlayState<T>();
}

class _GoDropdownOverlayState<T> extends State<GoDropdownOverlay<T>> {
  List<T> items = [];
  bool isLoading = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadItems(widget.query ?? '');
  }

  @override
  void didUpdateWidget(covariant GoDropdownOverlay<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _loadItems(widget.query ?? '');
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _loadItems(String query) async {
    _debounce?.cancel();
    _debounce = Timer(widget.requestDelay, () async {
      if (!mounted) return;
      setState(() => isLoading = true);
      final fetchedItems = await widget.items(query);
      if (!mounted) return;
      setState(() {
        items = fetchedItems;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final overlayHeight =
        widget.overlayHeight ?? ((items.length > 4 || items.isEmpty) ? 240.0 : null);

    final itemListWidget = _GoDropdownItem<T>(
      type: widget.type,
      items: items,
      selectedItem: widget.selectedItem,
      selectedItems: widget.selectedItems,
      listItemBuilder: widget.listItemBuilder,
      onChanged: widget.onChanged,
      onListChanged: widget.onListChanged,
      hideOverlay: widget.hideOverlay,
      hideOnSelect: widget.hideOnSelect,
    );
    return SizedBox(
      height: overlayHeight,
      child: Column(
        children: [
          widget.overlayHeader?.call(context, widget.hideOverlay) ??
              GestureDetector(
                onTap: widget.hideOverlay,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding:
                      Theme.of(context).inputDecorationTheme.contentPadding ??
                      const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.labelText ?? widget.hintText ?? '',
                          style: Theme.of(context).inputDecorationTheme.hintStyle,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_up),
                    ],
                  ),
                ),
              ),
          if (widget.showSearch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search',
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  isDense: true,
                ),
                onChanged: _loadItems,
              ),
            ),
          if (isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: widget.loadingIndicator ?? const Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(widget.noResultFoundText),
            )
          else
            overlayHeight != null ? Expanded(child: itemListWidget) : itemListWidget,
        ],
      ),
    );
  }
}

class _GoDropdownItem<T> extends StatefulWidget {
  const _GoDropdownItem({
    super.key,
    required this.type,
    required this.items,
    this.selectedItem,
    required this.selectedItems,
    this.listItemBuilder,
    this.onChanged,
    this.onListChanged,
    required this.hideOverlay,
    this.hideOnSelect = true,
  });

  final DropdownType type;
  final List<T> items;
  final T? selectedItem;
  final List<T> selectedItems;
  final Widget Function(BuildContext context, T item, bool isSelected)? listItemBuilder;
  final Function(T?)? onChanged;
  final Function(List<T>)? onListChanged;
  final VoidCallback hideOverlay;
  final bool hideOnSelect;

  @override
  State<_GoDropdownItem<T>> createState() => __GoDropdownItemState<T>();
}

class __GoDropdownItemState<T> extends State<_GoDropdownItem<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget defaultListItemBuilder(BuildContext context, T result, bool isSelected) {
    return ColoredBox(
      color: isSelected ? Theme.of(context).highlightColor : Colors.transparent,
      child: Padding(
        padding: EdgeInsets.all(widget.type == DropdownType.single ? 12.0 : 8.0),
        child: Row(
          spacing: 8.0,
          children: [
            if (widget.type == DropdownType.multiple)
              IgnorePointer(
                child: Checkbox(
                  onChanged: (_) {},
                  value: isSelected,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            Expanded(child: Text(_getDisplayText(result))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _scrollController,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          final isSelected = widget.type == DropdownType.single
              ? item == widget.selectedItem
              : widget.selectedItems.contains(item);
          return InkWell(
            onTap: () {
              if (widget.type == DropdownType.single) {
                widget.onChanged?.call(item);
                if (widget.hideOnSelect) widget.hideOverlay();
              } else {
                final selectedItems = List<T>.from(widget.selectedItems);
                if (isSelected) {
                  selectedItems.remove(item);
                } else {
                  selectedItems.add(item);
                }
                widget.onListChanged?.call(selectedItems);
              }
            },
            child: (widget.listItemBuilder ?? defaultListItemBuilder)(context, item, isSelected),
          );
        },
        itemCount: widget.items.length,
      ),
    );
  }
}
