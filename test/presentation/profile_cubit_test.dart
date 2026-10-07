import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/app/config/app_config.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/update_profile_request.dart';
import 'package:gp1/data/models/user.dart';
import 'package:gp1/presentation/auth/cubit/auth_cubit.dart';
import 'package:gp1/presentation/profile/cubit/profile_cubit.dart';

import '../helpers/fakes.dart';
import '../helpers/fixtures.dart';

/// Records the update it receives and answers with the user it would produce.
class _ProfileRepository extends FakeAuthRepository {
  UpdateProfileRequest? lastUpdate;
  Result<User> updateResult = Success(sampleUser.copyWith(name: 'New Name'));

  @override
  Future<Result<User>> updateProfile(UpdateProfileRequest request) async {
    lastUpdate = request;
    return updateResult;
  }
}

void main() {
  late _ProfileRepository repository;
  late AuthCubit auth;
  late ProfileCubit cubit;

  setUp(() {
    repository = _ProfileRepository();
    auth = AuthCubit(repository, InMemoryLocalDataBase());
    cubit = ProfileCubit(repository, auth);
  });

  group('changes', () {
    const user = User(
      id: 1,
      username: 'admin',
      email: 'a@x.io',
      name: 'Admin',
      phone: '0912',
      swagger: 'http://old',
    );

    UpdateProfileRequest changes({
      String name = 'Admin',
      String phone = '0912',
      String github = '',
      String figma = '',
      String swagger = 'http://old',
    }) => ProfileCubit.changes(
      user,
      name: name,
      phone: phone,
      github: github,
      figma: figma,
      swagger: swagger,
    );

    test('nothing differs, nothing is sent', () {
      expect(changes().hasNoChanges, isTrue);
    });

    test('only the edited fields are sent, trimmed', () {
      expect(changes(name: '  New Name ', github: 'https://github.com/x').toJson(), {
        'name': 'New Name',
        'github': 'https://github.com/x',
      });
    });

    test('clearing a field sends an empty string', () {
      expect(changes(phone: '').toJson(), {'phone': ''});
    });
  });

  test('load fetches the profile and gives it to AuthCubit', () async {
    repository.profileResult = Success(
      sampleUser.copyWith(name: 'Stored Name', swagger: 'http://s'),
    );

    await cubit.load();

    expect(repository.profileCalls, 1);
    expect(auth.state.user?.name, 'Stored Name');
    expect(auth.state.user?.swagger, 'http://s');
  });

  test('a failed load reports the failure', () async {
    repository.profileResult = const Failure(code: 500, message: 'Internal server error');

    await cubit.load();

    expect(cubit.state.failure?.message, 'Internal server error');
    expect(auth.state.user, isNull);
  });

  test('save sends the request and gives the saved user to AuthCubit', () async {
    const request = UpdateProfileRequest(name: 'New Name');

    await cubit.save(request);

    expect(repository.lastUpdate, request);
    expect(auth.state.user?.name, 'New Name');
    expect(cubit.state.message, 'Profile updated');
    expect(cubit.state.isBusy, isFalse);
  });

  test('save with nothing changed does not call the backend', () async {
    await cubit.save(const UpdateProfileRequest());

    expect(repository.lastUpdate, isNull);
  });

  test('a failed save reports the failure and keeps the user', () async {
    repository.updateResult = const Failure(code: 400, message: 'Invalid request data');

    await cubit.save(const UpdateProfileRequest(name: 'X'));

    expect(cubit.state.failure?.message, 'Invalid request data');
    expect(cubit.state.message, isNull);
    expect(auth.state.user, isNull);
  });

  test('uploadAvatar sends the image and updates the user', () async {
    repository.profileResult = Success(sampleUser.copyWith(avatar: '/uploads/avatars/1-ab.png'));

    await cubit.uploadAvatar(Uint8List.fromList([1, 2, 3]), 'me.png');

    expect(repository.lastAvatar, [1, 2, 3]);
    expect(auth.state.user?.avatar, '/uploads/avatars/1-ab.png');
    expect(cubit.state.message, 'Avatar updated');
  });

  test('a failed avatar upload reports the failure', () async {
    repository.profileResult = const Failure(code: 400, message: 'Avatar must be at most 2 MB');

    await cubit.uploadAvatar(Uint8List.fromList([1]), 'big.png');

    expect(cubit.state.failure?.message, 'Avatar must be at most 2 MB');
    expect(auth.state.user, isNull);
  });

  test('AppConfig.resolveUrl turns backend paths into full URLs', () {
    final base = AppConfig.baseUrl;
    expect(AppConfig.resolveUrl('/uploads/avatars/1.png'), '$base/uploads/avatars/1.png');
    expect(AppConfig.resolveUrl('uploads/avatars/1.png'), '$base/uploads/avatars/1.png');
    expect(AppConfig.resolveUrl('https://cdn.test/a.png'), 'https://cdn.test/a.png');
  });
}
