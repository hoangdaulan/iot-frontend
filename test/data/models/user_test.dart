import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/data/models/dto/change_password_request.dart';
import 'package:gp1/data/models/dto/login_request.dart';
import 'package:gp1/data/models/dto/login_response.dart';
import 'package:gp1/data/models/dto/register_request.dart';
import 'package:gp1/data/models/dto/register_response.dart';
import 'package:gp1/data/models/dto/update_profile_request.dart';
import 'package:gp1/data/models/user.dart';

void main() {
  group('User.fromJson', () {
    test('parses a full profile', () {
      final user = User.fromJson({
        'id': 7,
        'name': 'Leo Nguyen',
        'email': 'leo@example.com',
        'username': 'leo',
        'phone': '+84 912 345 678',
        'avatar': 'https://example.com/a.png',
        'github': 'https://github.com/leo',
        'figma': 'https://figma.com/@leo',
        'role': 'ADMIN',
      });

      expect(user.id, 7);
      expect(user.name, 'Leo Nguyen');
      expect(user.username, 'leo');
      expect(user.role, UserRole.admin);
      expect(user.github, 'https://github.com/leo');
    });

    test('parses the example payload from model-specification.md', () {
      final user = User.fromJson({
        'id': 1,
        'name': 'Nguyen Van A',
        'username': 'nguyenvana',
        'email': 'a@gmail.com',
        'phone': '0912345678',
        'avatar': '/uploads/avatar/1.jpg',
        'github': 'https://github.com/nguyenvana',
        'figma': 'https://figma.com/@nguyenvana',
        'role': 'USER',
      });

      expect(user.role, UserRole.user);
      expect(user.avatar, '/uploads/avatar/1.jpg');
    });

    test('leaves optional profile fields null when absent', () {
      final user = User.fromJson({'id': 1, 'email': 'a@b.c', 'username': 'a', 'role': 'USER'});

      expect(user.name, isNull);
      expect(user.phone, isNull);
      expect(user.avatar, isNull);
      expect(user.github, isNull);
      expect(user.figma, isNull);
    });

    test('maps unknown or missing role to UserRole.unknown', () {
      final base = {'id': 1, 'email': 'a@b.c', 'username': 'a'};

      expect(User.fromJson({...base, 'role': 'superuser'}).role, UserRole.unknown);
      expect(User.fromJson(base).role, UserRole.unknown);
    });

    test('accepts a numeric id sent as a double', () {
      final user = User.fromJson({'id': 3.0, 'email': 'a@b.c', 'username': 'a', 'role': 'USER'});

      expect(user.id, 3);
    });

    test('round-trips through toJson without emitting nulls', () {
      const user = User(id: 1, username: 'a', email: 'a@b.c', role: UserRole.user);
      final json = user.toJson();

      expect(json.containsKey('phone'), isFalse);
      expect(User.fromJson(json), user);
    });
  });

  test('UserRole serializes as ADMIN / USER', () {
    const admin = User(id: 1, username: 'a', email: 'a@b.c', role: UserRole.admin);

    expect(admin.toJson()['role'], 'ADMIN');
    expect(admin.copyWith(role: UserRole.user).toJson()['role'], 'USER');
    expect(
      User.fromJson({'id': 1, 'email': 'a@b.c', 'username': 'a', 'role': 'admin'}).role,
      UserRole.unknown,
      reason: 'wire values are case-sensitive',
    );
  });

  group('auth DTOs', () {
    test('LoginRequest serializes credentials', () {
      expect(const LoginRequest(username: 'admin', password: '123456').toJson(), {
        'username': 'admin',
        'password': '123456',
      });
    });

    test('LoginResponse parses the documented response with a partial user', () {
      final response = LoginResponse.fromJson({
        'accessToken': 'jwt',
        'user': {'id': 1, 'username': 'admin', 'name': 'Administrator', 'role': 'ADMIN'},
      });

      expect(response.accessToken, 'jwt');
      expect(response.refreshToken, isNull);
      expect(response.user.username, 'admin');
      expect(response.user.name, 'Administrator');
      expect(response.user.role, UserRole.admin);
      expect(LoginResponse.fromJson(response.toJson()), response);
    });

    test('RegisterRequest serializes username, email and password', () {
      expect(
        const RegisterRequest(
          username: 'user01',
          email: 'user01@gmail.com',
          password: '123456',
        ).toJson(),
        {'username': 'user01', 'email': 'user01@gmail.com', 'password': '123456'},
      );
    });

    test('RegisterRequest includes the full name when it is given', () {
      expect(
        const RegisterRequest(
          name: 'Nguyen Van A',
          username: 'user01',
          email: 'user01@gmail.com',
          password: '123456',
        ).toJson(),
        {
          'name': 'Nguyen Van A',
          'username': 'user01',
          'email': 'user01@gmail.com',
          'password': '123456',
        },
      );
    });

    test('RegisterResponse parses the documented 201 response', () {
      final response = RegisterResponse.fromJson({
        'message': 'Register successfully',
        'user': {'id': 2, 'username': 'Nguyen Van A', 'role': 'USER'},
      });

      expect(response.message, 'Register successfully');
      expect(response.user.id, 2);
      expect(response.user.name, isNull);
      expect(response.user.role, UserRole.user);
    });

    test('UpdateProfileRequest only sends the fields that changed', () {
      expect(const UpdateProfileRequest(phone: '0912345678').toJson(), {'phone': '0912345678'});
      expect(const UpdateProfileRequest(name: 'A', swagger: 'http://x/swagger').toJson(), {
        'name': 'A',
        'swagger': 'http://x/swagger',
      });
      expect(const UpdateProfileRequest().hasNoChanges, isTrue);
      expect(const UpdateProfileRequest(figma: '').hasNoChanges, isFalse);
    });

    test('User parses swagger and shows the full name, else the username', () {
      final user = User.fromJson({
        'id': 1,
        'username': 'admin',
        'email': 'a@x.io',
        'role': 'ADMIN',
        'name': ' Administrator ',
        'swagger': 'http://localhost:8080/swagger/index.html',
      });

      expect(user.swagger, 'http://localhost:8080/swagger/index.html');
      expect(user.displayName, 'Administrator');
      expect(user.copyWith(name: null).displayName, 'admin');
      expect(user.copyWith(name: '  ').displayName, 'admin');
    });

    test('ChangePasswordRequest serializes both passwords', () {
      expect(const ChangePasswordRequest(oldPassword: 'old', newPassword: 'new').toJson(), {
        'oldPassword': 'old',
        'newPassword': 'new',
      });
    });
  });
}
