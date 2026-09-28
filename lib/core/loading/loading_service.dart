import 'package:flutter/foundation.dart';
import 'package:gp1/core/di/injection.dart';
import 'package:injectable/injectable.dart';

@singleton
class LoadingService {
  final isLoading = ValueNotifier<bool>(false);
  int _loadingCount = 0;

  Future<void> show() async {
    _loadingCount++;
    if (!isLoading.value) {
      await Future.microtask(() => isLoading.value = true);
    }
  }

  Future<void> hide() async {
    _loadingCount--;
    if (_loadingCount <= 0) {
      _loadingCount = 0;
      if (isLoading.value) {
        await Future.microtask(() => isLoading.value = false);
      }
    }
  }

  Future<T> wrapLoading<T>(Future<T> Function() operation) async {
    try {
      await show();
      return await operation();
    } finally {
      await hide();
    }
  }

  @disposeMethod
  void dispose() {
    isLoading.dispose();
  }
}

// extension FutureLoadingExtension<T> on Future<T> {
//   Future<T> withLoading(LoadingService loadingService) {
//     return loadingService.wrapLoading(() => this);
//   }
// }

extension FutureLoadingExtension<T> on Future<T> {
  Future<T> withLoading() {
    return getIt<LoadingService>().wrapLoading(() => this);
  }
}
