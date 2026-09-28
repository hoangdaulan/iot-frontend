import 'package:flutter/material.dart';
import 'package:gp1/generated/colors.gen.dart';

class TableFilterAction extends StatelessWidget {
  const TableFilterAction({
    super.key,
    required this.onClear,
    required this.onCancel,
    required this.onApply,
  });

  final VoidCallback? onClear;
  final VoidCallback? onCancel;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(64, 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(64, 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          spacing: 4,
          children: [
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(foregroundColor: ColorName.red),
              child: const Text('Xoá lọc'),
            ),
            const Spacer(),
            TextButton(onPressed: onCancel, child: const Text('Hủy')),
            FilledButton(onPressed: onApply, child: const Text('Lọc')),
          ],
        ),
      ),
    );
  }
}
