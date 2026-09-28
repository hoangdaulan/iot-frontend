import 'package:flutter/material.dart';
import 'package:gp1/core/di/injection.dart';
import 'package:gp1/core/loading/loading_service.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:gp1/presentation/widgets/app_loading.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: getIt<LoadingService>().isLoading,
      child: child,
      builder: (context, isLoading, cachedChild) {
        return Stack(
          children: [
            cachedChild!,
            if (isLoading)
              Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: ColorName.black.withValues(alpha: 0.1),
                    child: const AppLoading(size: 36),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
