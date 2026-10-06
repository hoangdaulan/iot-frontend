import 'package:gp1/core/auth/auth_cubit_base.dart';
import 'package:gp1/core/base/local_data_base.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/mock/mock_users.dart';
import 'package:gp1/data/models/dto/login_request.dart';
import 'package:gp1/data/models/dto/login_response.dart';
import 'package:gp1/data/models/dto/register_request.dart';
import 'package:gp1/data/models/user.dart';
import 'package:gp1/data/repositories/auth_repository.dart';

class AuthState extends AuthStateBase {
  final Failure? failure;
  final String username;
  final String password;

  /// The signed-in user's profile; set whenever [isAuthenticated] is true.
  final User? user;

  const AuthState({
    super.isAuthenticated = false,
    this.failure,
    this.username = mockLoginUsername,
    this.password = mockLoginPassword,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    Failure? failure,
    String? username,
    String? password,
    User? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      failure: failure,
      username: username ?? this.username,
      password: password ?? this.password,
      user: user ?? this.user,
    );
  }
}

class AuthCubit extends AuthCubitBase<AuthState> {
  AuthCubit(this._authRepository, this._localDataBase) : super(const AuthState());

  static const _unauthorized = 401;

  final AuthRepository _authRepository;
  final LocalDataBase _localDataBase;

  /// Restores the session from a saved access token.
  ///
  /// No token, or a token the backend rejects (401), leads to the login screen; the rejected
  /// token is removed. Any other failure (network, 5xx) also shows the login screen but keeps
  /// the token, so the session is restored on the next start once the backend is reachable.
  Future<void> init() async {
    final token = await _localDataBase.getAccessToken();
    if (token == null || token.isEmpty) {
      emit(const AuthState());
      return;
    }

    final result = await _authRepository.getProfile();
    switch (result) {
      case Success(data: final user):
        emit(AuthState(isAuthenticated: true, user: user));
      case Failure(code: _unauthorized):
        await _localDataBase.clearTokens();
        emit(const AuthState());
      case Failure():
        emit(AuthState(failure: result));
    }
  }

  /// Replaces the signed-in user's profile after it was edited, so every screen shows it.
  void updateUser(User user) => emit(state.copyWith(user: user));

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

    final loginResult = await _authRepository.login(
      LoginRequest(username: username, password: password),
    );
    final LoginResponse session;
    switch (loginResult) {
      case Success(data: final data):
        session = data;
      case Failure():
        emit(state.copyWith(failure: loginResult));
        return;
    }
    await _localDataBase.saveAccessToken(session.accessToken);
    if (session.refreshToken case final refreshToken?) {
      await _localDataBase.saveRefreshToken(refreshToken);
    }

    // The login response only carries a user summary; load the full profile with the new token.
    final profileResult = await _authRepository.getProfile();
    switch (profileResult) {
      case Success(data: final user):
        emit(state.copyWith(isAuthenticated: true, user: user));
      case Failure():
        await _localDataBase.clearTokens();
        emit(state.copyWith(failure: profileResult));
    }
  }

  /// Returns whether the account was created. Failures are reported through [AuthState.failure].
  Future<bool> register(RegisterRequest request) async {
    final result = await _authRepository.register(request);
    switch (result) {
      case Success():
        return true;
      case Failure():
        emit(state.copyWith(failure: result));
        return false;
    }
  }

  @override
  Future<void> logout() async {
    await _localDataBase.clearTokens();
    emit(const AuthState());
  }
}
