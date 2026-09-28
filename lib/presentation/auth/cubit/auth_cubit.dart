import 'package:gp1/core/auth/auth_cubit_base.dart';
import 'package:gp1/core/base/result.dart';

class AuthState extends AuthStateBase {
  final Failure? failure;
  final String username;
  final String password;

  const AuthState({
    super.isAuthenticated = false,
    this.failure,
    this.username = 'admin',
    this.password = '123456',
  });

  AuthState copyWith({
    bool? isAuthenticated,
    Failure? failure,
    String? username,
    String? password,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      failure: failure,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }
}

class AuthCubit extends AuthCubitBase<AuthState> {
  AuthCubit() : super(const AuthState());

  Future<void> init() async {
    // Mock: start unauthenticated with default mock credentials pre-filled
    emit(const AuthState(
      isAuthenticated: false,
      username: 'admin',
      password: '123456',
    ));
  }

  void updateUsername(String username) {
    emit(state.copyWith(username: username));
  }

  void updatePassword(String password) {
    emit(state.copyWith(password: password));
  }

  Future<void> login() async {
    final username = state.username.trim();
    final password = state.password;

    if (username.isEmpty || password.isEmpty) {
      emit(state.copyWith(failure: const Failure(message: 'Please enter username and password')));
      emit(state.copyWith(failure: null));
      return;
    }

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    emit(state.copyWith(isAuthenticated: true));
  }

  @override
  void logout() {
    emit(const AuthState(
      isAuthenticated: false,
      username: 'admin',
      password: '123456',
    ));
  }
}
