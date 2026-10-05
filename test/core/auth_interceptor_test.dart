import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/core/auth/auth_cubit_base.dart';
import 'package:gp1/core/auth/auth_interceptor.dart';
import 'package:gp1/core/base/local_data_base.dart';
import 'package:gp1/core/di/injection.dart';
import 'package:gp1/presentation/auth/cubit/auth_cubit.dart';

import '../helpers/fakes.dart';

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.statusCode);

  final int statusCode;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      '{}',
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late InMemoryLocalDataBase storage;

  Dio dioWith(_RecordingAdapter adapter) => Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter
    ..interceptors.add(AuthInterceptor());

  setUp(() {
    storage = InMemoryLocalDataBase();
    getIt.registerSingleton<LocalDataBase>(storage);
    getIt.registerSingleton<AuthCubitBase>(AuthCubit(FakeAuthRepository(), storage));
  });

  tearDown(() => getIt.reset());

  test('attaches "Authorization: Bearer <accessToken>" when a token is saved', () async {
    storage.accessToken = 'jwt-token';
    final adapter = _RecordingAdapter(200);

    await dioWith(adapter).get<Object?>('/api/auth/profile');

    expect(adapter.lastRequest?.headers['Authorization'], 'Bearer jwt-token');
  });

  test('sends no Authorization header without a token', () async {
    final adapter = _RecordingAdapter(200);

    await dioWith(adapter).post<Object?>('/api/auth/login', data: {'username': 'admin'});

    expect(adapter.lastRequest?.headers.containsKey('Authorization'), isFalse);
  });

  test('a 401 without a refresh token signs out and removes the invalid token', () async {
    storage.accessToken = 'expired-jwt';
    final adapter = _RecordingAdapter(401);

    await expectLater(dioWith(adapter).get<Object?>('/api/devices'), throwsA(isA<DioException>()));
    await Future<void>.delayed(Duration.zero);

    expect(storage.accessToken, isNull);
    expect(getIt<AuthCubitBase>().state.isAuthenticated, isFalse);
  });

  test('a 401 on an unauthenticated request (wrong login) does not sign out', () async {
    final authCubit = getIt<AuthCubitBase>() as AuthCubit;
    authCubit.updateUsername('typed-by-user');
    final adapter = _RecordingAdapter(401);

    await expectLater(
      dioWith(adapter).post<Object?>('/api/auth/login', data: {'username': 'typed-by-user'}),
      throwsA(isA<DioException>()),
    );
    await Future<void>.delayed(Duration.zero);

    expect(authCubit.state.username, 'typed-by-user');
  });
}
