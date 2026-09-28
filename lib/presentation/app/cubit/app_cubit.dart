import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/app/navigation/app_route.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/mock/mock_data.dart';
import 'package:gp1/presentation/app/models/app_info.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'navigation_extension.dart';

class AppState {
  final String username;
  final String email;
  final String phone;
  final String role;
  final String github;
  final String figma;
  final AppInfo appInfo;
  final Failure? failure;

  const AppState({
    this.username = '',
    this.email = '',
    this.phone = '',
    this.role = '',
    this.github = '',
    this.figma = '',
    this.appInfo = const AppInfo(),
    this.failure,
  });

  AppState copyWith({
    String? username,
    String? email,
    String? phone,
    String? role,
    String? github,
    String? figma,
    AppInfo? appInfo,
    Failure? failure,
  }) {
    return AppState(
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      github: github ?? this.github,
      figma: figma ?? this.figma,
      appInfo: appInfo ?? this.appInfo,
      failure: failure,
    );
  }
}

class AppCubit extends Cubit<AppState> {
  AppCubit() : super(const AppState()) {
    initAppInfo();
  }

  Future<void> initAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appInfo = AppInfo.fromPackageInfo(packageInfo);
    emit(state.copyWith(appInfo: appInfo));
  }

  Future<void> load() async {
    // Load mock user data
    emit(state.copyWith(
      username: MockData.mockUsername,
      email: MockData.mockEmail,
      phone: MockData.mockPhone,
      role: MockData.mockRole,
      github: MockData.mockGithub,
      figma: MockData.mockFigma,
    ));
  }

  void updatePhone(String phone) => emit(state.copyWith(phone: phone));
  void updateGithub(String github) => emit(state.copyWith(github: github));
  void updateFigma(String figma) => emit(state.copyWith(figma: figma));

  Future<void> clear() async {
    emit(const AppState());
  }
}
