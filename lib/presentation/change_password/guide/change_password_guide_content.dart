import 'package:flutter/material.dart';
import 'package:gp1/presentation/widgets/guide.dart';

class ChangePassGuide extends StatelessWidget {
  const ChangePassGuide({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GuideSteps(stepNumber: 1, stepText: 'Bước 1: Nhấn "Thay đổi mật khẩu"'),
        GuideSteps(stepNumber: 2, stepText: 'Bước 2: Nhập mật khẩu cũ (Mật khẩu đang sử dụng)'),
        GuideSteps(stepNumber: 3, stepText: 'Bước 3: Nhập mật khẩu mới'),
        GuideSteps(
          stepNumber: 4,
          stepText: 'Bước 4: Nhập lại mật khẩu mới (Xác nhận mật khẩu mới)',
        ),
        GuideSteps(stepNumber: 5, stepText: 'Bước 5: Nhấn đặt lại mật khẩu để hoàn thành đặt lại'),
      ],
    );
  }
}
