import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/app/navigation/app_route.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/user.dart';
import 'package:gp1/presentation/app/models/app_info.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'navigation_extension.dart';

class AppState {
  final User? user;
  final AppInfo appInfo;
  final Failure? failure;

  const AppState({this.user, this.appInfo = const AppInfo(), this.failure});

  AppState copyWith({User? user, AppInfo? appInfo, Failure? failure}) {
    return AppState(user: user ?? this.user, appInfo: appInfo ?? this.appInfo, failure: failure);
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

  /// Shows the profile of the user [AuthCubit] signed in.
  void setUser(User user) => emit(state.copyWith(user: user));

  // Profile edits are local only until a profile update endpoint exists.
  void updatePhone(String phone) => _updateUser((user) => user.copyWith(phone: phone));
  void updateGithub(String github) => _updateUser((user) => user.copyWith(github: github));
  void updateFigma(String figma) => _updateUser((user) => user.copyWith(figma: figma));

  void _updateUser(User Function(User user) update) {
    final user = state.user;
    if (user == null) return;
    emit(state.copyWith(user: update(user)));
  }

  Future<void> clear() async {
    emit(const AppState());
  }
}
