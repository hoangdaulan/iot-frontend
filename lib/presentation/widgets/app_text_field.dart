import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gp1/core/utils/extensions/double_extensions.dart';
import 'package:gp1/presentation/widgets/models/app_field_style.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.value,
    this.onChanged,
    this.validator,
    this.isDoubleNumber = false,

    this.style = AppFieldStyle.normal,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,

    this.readOnly = false,
    this.enabled,
    this.obscureText = false,
    this.autocorrect = false,

    this.maxLines = 1,
    this.maxLength,

    this.onTap,
    this.onTapOutside,
    this.onEditingComplete,
    this.onFieldSubmitted,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? value;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool isDoubleNumber;

  final AppFieldStyle style;
  final InputDecoration decoration;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;

  final bool readOnly;
  final bool? enabled;
  final bool obscureText;
  final bool autocorrect;

  final int? maxLines;
  final int? maxLength;

  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final TextEditingController _controller;

  /// A controller passed in belongs to the caller: it is neither disposed here nor overwritten
  /// by a missing [AppTextField.value].
  bool get _ownsController => widget.controller == null;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateControllerValue());
  }

  void _updateControllerValue() {
    if (!_ownsController && widget.value == null) return;

    final value = widget.value ?? '';
    if (_controller.text == value) return;

    if (widget.isDoubleNumber) {
      final currentDouble = double.tryParse(_controller.text.replaceAll(',', '.'));
      final newDouble = double.tryParse(value.replaceAll(',', '.'));
      if (currentDouble != null && newDouble != null && currentDouble.isCloseTo(newDouble)) {
        return;
      }
    }

    final selection = _controller.selection;
    final length = value.length;

    _controller.value = TextEditingValue(
      text: value,
      selection: selection.isValid
          ? selection.copyWith(
              baseOffset: selection.baseOffset.clamp(0, length),
              extentOffset: selection.extentOffset.clamp(0, length),
            )
          : TextSelection.collapsed(offset: length),
      composing: TextRange.empty,
    );
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      validator: widget.validator,

      decoration: widget.style.getInputDecoration(base: widget.decoration),
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      textCapitalization: widget.textCapitalization,
      textInputAction: widget.textInputAction,

      readOnly: widget.readOnly,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,

      maxLines: widget.maxLines,
      maxLength: widget.maxLength,

      onTap: widget.onTap,
      onTapOutside: widget.onTapOutside,
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onFieldSubmitted,
    );
  }
}
