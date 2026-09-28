import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:gp1/core/auth/auth_cubit_base.dart';
import 'package:gp1/core/auth/auth_notifier.dart';
import 'package:gp1/core/loading/loading_service.dart';
import 'package:gp1/presentation/app/cubit/app_cubit.dart';
import 'package:gp1/presentation/auth/cubit/auth_cubit.dart';
import 'package:gp1/presentation/change_password/cubit/change_password_cubit.dart';
import 'package:talker_flutter/talker_flutter.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies() {
  // Core services
  getIt.registerSingleton<LoadingService>(LoadingService());

  getIt.registerLazySingleton<Talker>(
    () => TalkerFlutter.init(settings: TalkerSettings(useConsoleLogs: kDebugMode)),
  );

  // Auth
  getIt.registerSingleton<AuthCubit>(AuthCubit());

  getIt.registerLazySingleton<AuthCubitBase<AuthStateBase>>(
    () => getIt<AuthCubit>(),
  );

  getIt.registerLazySingleton<AuthNotifier>(
    () => AuthNotifier(getIt<AuthCubitBase<AuthStateBase>>()),
  );

  // App & Features
  getIt.registerFactory<AppCubit>(() => AppCubit());
  getIt.registerFactory<ChangePasswordCubit>(() => ChangePasswordCubit());
}
