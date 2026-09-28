import 'package:flutter/material.dart';
import 'package:gp1/presentation/widgets/guide.dart';

class LoginGuideContent extends StatelessWidget {
  const LoginGuideContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideSteps(stepNumber: 1, stepText: 'Bước 1: Nhập tài khoản (VD: user01)'),
        GuideSteps(stepNumber: 2, stepText: 'Bước 2: Nhập mật khẩu (VD: 1234)'),
        GuideSteps(stepNumber: 3, stepText: 'Bước 3: Nhấn nút đăng nhập'),
      ],
    );
  }
}
