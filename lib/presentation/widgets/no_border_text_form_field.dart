import 'package:flutter/material.dart';

class NoBorderTextFormField extends StatelessWidget {
  const NoBorderTextFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.onChanged,
    this.readOnly = false,
    this.maxLines,
    this.validator,
  });

  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final int? maxLines;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      validator: validator,
    );
  }
}
