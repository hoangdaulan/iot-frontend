import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/local/shared_preferences_local_data_base.dart';
import 'package:gp1/data/mock/mock_users.dart';
import 'package:gp1/data/models/dto/register_request.dart';
import 'package:gp1/presentation/auth/cubit/auth_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeAuthRepository repository;

  setUp(() => repository = FakeAuthRepository());

  group('startup (init)', () {
    test('without a saved token stays signed out and does not call the profile API', () async {
      final storage = InMemoryLocalDataBase();
      final cubit = AuthCubit(repository, storage);

      await cubit.init();

      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.failure, isNull);
      expect(repository.profileCalls, 0);
    });

    test('with a valid token restores the session from the profile', () async {
      final storage = InMemoryLocalDataBase(accessToken: 'saved-jwt');
      final cubit = AuthCubit(repository, storage);

      await cubit.init();

      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.user, mockUser);
      expect(storage.accessToken, 'saved-jwt');
    });

    test('with a token rejected by the profile API (401) clears it and signs out', () async {
      final storage = InMemoryLocalDataBase(accessToken: 'expired-jwt', refreshToken: 'r');
      repository.profileResult = const Failure(code: 401, message: 'Unauthorized');
      final cubit = AuthCubit(repository, storage);

      await cubit.init();

      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.failure, isNull);
      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    });

    test('on a network or server error keeps the token and reports the failure', () async {
      final storage = InMemoryLocalDataBase(accessToken: 'saved-jwt');
      repository.profileResult = const Failure(code: 503, message: 'Service unavailable');
      final cubit = AuthCubit(repository, storage);

      await cubit.init();

      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.failure?.message, 'Service unavailable');
      expect(storage.accessToken, 'saved-jwt');
    });
  });

  group('login', () {
    test('saves the access token, loads the profile and signs in', () async {
      final storage = InMemoryLocalDataBase();
      final cubit = AuthCubit(repository, storage);

      await cubit.login();

      expect(repository.lastLogin?.username, mockLoginUsername);
      expect(storage.accessToken, 'jwt-token');
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.user, mockUser);
    });

    test('does not save a token when the credentials are rejected', () async {
      final storage = InMemoryLocalDataBase();
      repository.loginResult = const Failure(code: 401, message: 'Invalid email or password');
      final cubit = AuthCubit(repository, storage);

      await cubit.login();

      expect(storage.accessToken, isNull);
      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.failure?.message, 'Invalid email or password');
    });

    test('persists only the token, never the password', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = AuthCubit(repository, SharedPreferencesLocalDataBase());

      await cubit.login();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), {'auth.accessToken'});
      expect(prefs.getString('auth.accessToken'), 'jwt-token');
    });
  });

  test('logout removes the saved token', () async {
    final storage = InMemoryLocalDataBase();
    final cubit = AuthCubit(repository, storage);
    await cubit.login();

    await cubit.logout();

    expect(storage.accessToken, isNull);
    expect(cubit.state.isAuthenticated, isFalse);
    expect(cubit.state.user, isNull);
  });

  group('register', () {
    const request = RegisterRequest(username: 'user01', email: 'u@x.io', password: '123456');

    test('sends the request and reports success', () async {
      final cubit = AuthCubit(repository, InMemoryLocalDataBase());

      expect(await cubit.register(request), isTrue);
      expect(repository.lastRegister?.email, 'u@x.io');
    });

    test('reports a conflict through the state failure', () async {
      repository.registerResult = const Failure(
        code: 409,
        message: 'Username or email already exists',
      );
      final cubit = AuthCubit(repository, InMemoryLocalDataBase());

      expect(await cubit.register(request), isFalse);
      expect(cubit.state.failure?.message, 'Username or email already exists');
    });
  });
}
