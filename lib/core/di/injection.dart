import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gp1/app/config/app_config.dart';
import 'package:get_it/get_it.dart';
import 'package:gp1/core/auth/auth_cubit_base.dart';
import 'package:gp1/core/auth/auth_notifier.dart';
import 'package:gp1/core/base/local_data_base.dart';
import 'package:gp1/core/loading/loading_service.dart';
import 'package:gp1/data/local/shared_preferences_local_data_base.dart';
import 'package:gp1/data/remote/api_client.dart';
import 'package:gp1/data/repositories/api/api_auth_repository.dart';
import 'package:gp1/data/repositories/api/api_device_repository.dart';
import 'package:gp1/data/repositories/api/api_sensor_repository.dart';
import 'package:gp1/data/repositories/auth_repository.dart';
import 'package:gp1/data/repositories/device_repository.dart';
import 'package:gp1/data/repositories/mock/mock_auth_repository.dart';
import 'package:gp1/data/repositories/mock/mock_device_repository.dart';
import 'package:gp1/data/repositories/mock/mock_sensor_repository.dart';
import 'package:gp1/data/repositories/mock_history_device_repository.dart';
import 'package:gp1/data/repositories/sensor_repository.dart';
import 'package:gp1/presentation/app/cubit/app_cubit.dart';
import 'package:gp1/presentation/auth/cubit/auth_cubit.dart';
import 'package:gp1/presentation/change_password/cubit/change_password_cubit.dart';
import 'package:gp1/presentation/control_history/cubit/control_history_cubit.dart';
import 'package:gp1/presentation/dashboard/cubit/dashboard_cubit.dart';
import 'package:gp1/presentation/sensors/cubit/sensors_cubit.dart';
import 'package:talker_flutter/talker_flutter.dart';

final GetIt getIt = GetIt.instance;

void configureDependencies() {
  // Core services
  getIt.registerSingleton<LoadingService>(LoadingService());

  getIt.registerLazySingleton<Talker>(
    () => TalkerFlutter.init(settings: TalkerSettings(useConsoleLogs: kDebugMode)),
  );

  // Token storage (also read by AuthInterceptor)
  getIt.registerLazySingleton<LocalDataBase>(() => SharedPreferencesLocalDataBase());

  // Repositories: the REST backend, or in-memory mocks with --dart-define=USE_MOCK_API=true
  if (AppConfig.useMockApi) {
    getIt.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
    getIt.registerLazySingleton<SensorRepository>(() => MockSensorRepository());
    getIt.registerLazySingleton<DeviceRepository>(() => MockDeviceRepository());
  } else {
    getIt.registerLazySingleton<Dio>(() => createApiClient(talker: getIt<Talker>()));
    getIt.registerLazySingleton<AuthRepository>(() => ApiAuthRepository(getIt<Dio>()));
    getIt.registerLazySingleton<SensorRepository>(() => ApiSensorRepository(getIt<Dio>()));
    // The control history is mock data, not the database; devices and commands use the backend.
    getIt.registerLazySingleton<DeviceRepository>(
      () => MockHistoryDeviceRepository(ApiDeviceRepository(getIt<Dio>()), MockDeviceRepository()),
    );
  }

  // Auth
  getIt.registerSingleton<AuthCubit>(AuthCubit(getIt<AuthRepository>(), getIt<LocalDataBase>()));

  getIt.registerLazySingleton<AuthCubitBase<AuthStateBase>>(() => getIt<AuthCubit>());

  getIt.registerLazySingleton<AuthNotifier>(
    () => AuthNotifier(getIt<AuthCubitBase<AuthStateBase>>()),
  );

  // App & Features
  getIt.registerFactory<AppCubit>(() => AppCubit());
  getIt.registerFactory<ChangePasswordCubit>(() => ChangePasswordCubit(getIt<AuthRepository>()));
  getIt.registerFactory<DashboardCubit>(
    () => DashboardCubit(getIt<SensorRepository>(), getIt<DeviceRepository>()),
  );
  getIt.registerFactory<SensorsCubit>(() => SensorsCubit(getIt<SensorRepository>()));
  getIt.registerFactory<ControlHistoryCubit>(() => ControlHistoryCubit(getIt<DeviceRepository>()));
}
