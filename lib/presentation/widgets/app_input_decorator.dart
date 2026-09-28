import 'package:flutter/material.dart';
import 'package:gp1/presentation/widgets/models/app_field_style.dart';

class AppInputDecorator extends StatelessWidget {
  const AppInputDecorator({
    super.key,
    this.style = AppFieldStyle.normal,
    required this.decoration,
    this.textAlign,
    this.textAlignVertical,
    this.child,
  });

  final AppFieldStyle style;
  final InputDecoration decoration;
  final TextAlign? textAlign;
  final TextAlignVertical? textAlignVertical;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: style.getInputDecoration(base: decoration),
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      child: child,
    );
  }
}
