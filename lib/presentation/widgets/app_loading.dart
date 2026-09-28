import 'package:flutter/material.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.dotsTriangle(color: ColorName.primary, size: size),
    );
  }
}
