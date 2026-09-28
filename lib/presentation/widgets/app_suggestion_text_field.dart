import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gp1/core/ui/animated_overlay/animated_overlay.dart';
import 'package:gp1/core/ui/go_dropdown/go_dropdown.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/widgets/app_loading.dart';
import 'package:gp1/presentation/widgets/app_text_field.dart';
import 'package:gp1/presentation/widgets/dropdown/app_dropdown_search_type.dart';
import 'package:gp1/presentation/widgets/models/app_field_style.dart';

String _getDisplayText(Object? item) {
  if (item == null) return '';
  if (item is GoDropdownDisplayText) {
    return item.displayText;
  }
  return item.toString();
}

class AppSuggestionTextField<T> extends StatefulWidget {
  const AppSuggestionTextField({
    super.key,
    this.searchType = AppDropdownSearchType.debounceSearch,
    required this.items,
    this.selectedItem,
    this.onSelectItem,

    this.value,
    this.onChanged,
    this.validator,

    this.noMatchErrorText,

    this.style = AppFieldStyle.normal,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,

    this.readOnly = false,
    this.enabled,
  });

  final AppDropdownSearchType searchType;

  final FutureOr<List<T>> Function(String) items;
  final T? selectedItem;
  final ValueChanged<T?>? onSelectItem;

  final String? value;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  /// Error message displayed when no suggestion is found.
  ///
  /// When null, the field does not validate whether the entered value
  /// has a matching suggestion.
  final String? noMatchErrorText;

  final AppFieldStyle style;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  final bool readOnly;
  final bool? enabled;

  @override
  State<AppSuggestionTextField<T>> createState() => _AppSuggestionTextFieldState<T>();
}

class _AppSuggestionTextFieldState<T> extends State<AppSuggestionTextField<T>> {
  VoidCallback? _hideOverlay;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  List<T> _items = [];
  String? _loadedQuery;
  bool _hasNoMatchError = false;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppSuggestionTextField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
      _hasNoMatchError = false;
    }
    if (widget.noMatchErrorText == null && _hasNoMatchError) {
      _hasNoMatchError = false;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _confirmFirstMatchedItem();
    }
  }

  Future<void> _confirmFirstMatchedItem() async {
    await Future.delayed(Durations.short1);
    if (!mounted) return;

    final currentText = _controller.text;
    final cachedItems = List<T>.from(_items);
    final cachedQuery = _loadedQuery;
    _hideOverlay?.call();

    if (currentText.isEmpty) {
      _selectItem(null);
      return;
    }

    if (cachedQuery == currentText) {
      if (cachedItems.isNotEmpty) {
        _selectItem(cachedItems.first);
      } else {
        _setMatchError(true);
      }
      return;
    }

    final currentRequestId = ++_requestId;
    final items = await widget.items(currentText);
    if (!mounted || currentRequestId != _requestId || _controller.text != currentText) {
      return;
    }
    if (items.isNotEmpty) {
      _selectItem(items.first);
    } else {
      _setMatchError(true);
    }
  }

  void _setMatchError(bool hasError) {
    if (widget.noMatchErrorText != null && _hasNoMatchError != hasError) {
      setState(() => _hasNoMatchError = hasError);
    }
  }

  void _selectItem(T? item) {
    _hideOverlay?.call();
    _setMatchError(false);
    if (item != null) {
      final displayText = _getDisplayText(item);
      _controller.text = displayText;
      widget.onSelectItem?.call(item);
    } else {
      widget.onSelectItem?.call(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final delay = widget.searchType == AppDropdownSearchType.debounceSearch
        ? const Duration(milliseconds: 500)
        : Duration.zero;

    final effectiveDecoration = _hasNoMatchError && widget.noMatchErrorText != null
        ? widget.decoration.copyWith(errorText: widget.noMatchErrorText)
        : widget.decoration;

    return AnimatedOverlay(
      direction: .bottom,
      alignment: .bottomLeft,
      overlayDecoration: BoxDecoration(
        color: ColorName.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      overlay: (hideOverlay) {
        _hideOverlay = () {
          hideOverlay();
          _items.clear();
          _loadedQuery = null;
        };
        return _SuggestionOverlay<T>(
          fetchItems: widget.items,
          controller: _controller,
          selectedItem: widget.selectedItem,
          requestDelay: delay,
          onSelectItem: _selectItem,
          onItemsLoaded: (items, query) {
            setState(() {
              _items = items;
              _loadedQuery = query;
            });
          },
        );
      },
      child: (showOverlay) {
        return AppTextField(
          controller: _controller,
          focusNode: _focusNode,
          onFieldSubmitted: (_) {
            _confirmFirstMatchedItem();
          },
          value: _controller.text,
          onTap: () {
            if (_controller.text.isEmpty) return;
            showOverlay();
          },
          onChanged: (value) {
            _setMatchError(false);
            widget.onChanged?.call(value);
            if (value.isEmpty) {
              _hideOverlay?.call();
            } else {
              showOverlay();
            }
          },
          validator: (value) {
            final customError = widget.validator?.call(value);
            if (customError != null) return customError;
            if (_hasNoMatchError && widget.noMatchErrorText != null) {
              return widget.noMatchErrorText;
            }
            return null;
          },

          style: widget.style,
          decoration: effectiveDecoration,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          textInputAction: widget.textInputAction,

          readOnly: widget.readOnly,
          enabled: widget.enabled,
        );
      },
    );
  }
}

class _SuggestionOverlay<T> extends StatefulWidget {
  const _SuggestionOverlay({
    required this.fetchItems,
    required this.controller,
    required this.onSelectItem,
    this.selectedItem,
    required this.requestDelay,
    required this.onItemsLoaded,
  });

  final FutureOr<List<T>> Function(String) fetchItems;
  final TextEditingController controller;
  final ValueChanged<T> onSelectItem;
  final T? selectedItem;
  final Duration requestDelay;
  final void Function(List<T> items, String query) onItemsLoaded;

  @override
  State<_SuggestionOverlay<T>> createState() => _SuggestionOverlayState<T>();
}

class _SuggestionOverlayState<T> extends State<_SuggestionOverlay<T>> {
  List<T> _items = [];
  bool _isLoading = false;
  Timer? _debounce;
  int _overlayRequestId = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _loadItems(widget.controller.text);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    _loadItems(widget.controller.text);
  }

  void _loadItems(String query) {
    _debounce?.cancel();
    _debounce = Timer(widget.requestDelay, () async {
      if (!mounted) return;
      final currentRequestId = ++_overlayRequestId;
      setState(() => _isLoading = true);
      final fetchedItems = await widget.fetchItems(query);
      if (!mounted || currentRequestId != _overlayRequestId || widget.controller.text != query) {
        return;
      }
      setState(() {
        _items = fetchedItems;
        _isLoading = false;
      });
      widget.onItemsLoaded(fetchedItems, query);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 100, child: Center(child: AppLoading(size: 24)));
    }

    if (_items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: Text('Không tìm thấy kết quả')),
      );
    }

    final overlayHeight = (_items.length > 4) ? 240.0 : null;
    final listWidget = _SuggestionItem(
      items: _items,
      controller: widget.controller,
      selectedItem: widget.selectedItem,
      onSelectItem: widget.onSelectItem,
    );

    if (overlayHeight != null) {
      return SizedBox(height: overlayHeight, child: listWidget);
    }
    return listWidget;
  }
}

class _SuggestionItem<T> extends StatefulWidget {
  const _SuggestionItem({
    super.key,
    required this.items,
    required this.controller,
    required this.selectedItem,
    required this.onSelectItem,
  });

  final List<T> items;
  final TextEditingController controller;
  final T? selectedItem;
  final ValueChanged<T> onSelectItem;

  @override
  State<_SuggestionItem<T>> createState() => _SuggestionItemState<T>();
}

class _SuggestionItemState<T> extends State<_SuggestionItem<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
          final isFirstItemHighlighted = index == 0 && widget.controller.text.isNotEmpty;
          final isSelected = item == widget.selectedItem || isFirstItemHighlighted;
          return InkWell(
            onTap: () => widget.onSelectItem(item),
            child: ColoredBox(
              color: isSelected ? Theme.of(context).highlightColor : Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(children: [Expanded(child: Text(_getDisplayText(item)))]),
              ),
            ),
          );
        },
        itemCount: widget.items.length,
      ),
    );
  }
}
