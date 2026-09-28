import 'package:flutter/material.dart';
import 'package:gp1/generated/assets.gen.dart';

class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  const AppLogo({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Assets.images.logoKaizenGo.image(width: width, height: height);
  }
}
