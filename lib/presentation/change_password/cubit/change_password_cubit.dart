import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/change_password_request.dart';
import 'package:gp1/data/repositories/auth_repository.dart';

class ChangePasswordState {
  final bool isSuccess;
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;
  final Failure? failure;

  const ChangePasswordState({
    this.isSuccess = false,
    this.oldPassword = '',
    this.newPassword = '',
    this.confirmPassword = '',
    this.failure,
  });

  ChangePasswordState copyWith({
    bool? isSuccess,
    String? oldPassword,
    String? newPassword,
    String? confirmPassword,
    Failure? failure,
  }) {
    return ChangePasswordState(
      isSuccess: isSuccess ?? this.isSuccess,
      oldPassword: oldPassword ?? this.oldPassword,
      newPassword: newPassword ?? this.newPassword,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      failure: failure,
    );
  }
}

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit(this._authRepository) : super(const ChangePasswordState());

  final AuthRepository _authRepository;

  void updateOldPassword(String oldPassword) {
    emit(state.copyWith(oldPassword: oldPassword));
  }

  void updateNewPassword(String newPassword) {
    emit(state.copyWith(newPassword: newPassword));
  }

  void updateConfirmPassword(String confirmPassword) {
    emit(state.copyWith(confirmPassword: confirmPassword));
  }

  Future<void> changePassword() async {
    final result = await _authRepository.changePassword(
      ChangePasswordRequest(oldPassword: state.oldPassword, newPassword: state.newPassword),
    );
    switch (result) {
      case Success():
        emit(state.copyWith(isSuccess: true));
      case Failure():
        emit(state.copyWith(failure: result));
    }
  }
}
