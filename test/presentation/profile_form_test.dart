import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/mock/mock_users.dart';
import 'package:gp1/data/models/dto/update_profile_request.dart';
import 'package:gp1/data/models/user.dart';
import 'package:gp1/presentation/app/cubit/app_cubit.dart';
import 'package:gp1/presentation/auth/cubit/auth_cubit.dart';
import 'package:gp1/presentation/profile/cubit/profile_cubit.dart';
import 'package:gp1/presentation/profile/widgets/profile_action_section.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../helpers/fakes.dart';

class _Repository extends FakeAuthRepository {
  UpdateProfileRequest? lastUpdate;

  @override
  Future<Result<User>> updateProfile(UpdateProfileRequest request) async {
    lastUpdate = request;
    return profileResult;
  }
}

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'app',
      packageName: 'app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Future<(_Repository, AppCubit)> pump(WidgetTester tester) async {
    final repository = _Repository();
    final auth = AuthCubit(repository, InMemoryLocalDataBase());
    final app = AppCubit()..setUser(mockUser);
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: app),
            BlocProvider(create: (_) => ProfileCubit(repository, auth)),
          ],
          child: const Scaffold(body: CustomScrollView(slivers: [ProfileActionSection()])),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (repository, app);
  }

  testWidgets('shows every profile field; the username and email are read only', (tester) async {
    await pump(tester);

    for (final (label, value) in [
      ('Username', mockUser.username),
      ('Email', mockUser.email),
      ('Full name', mockUser.name!),
      ('Phone', mockUser.phone!),
      ('GitHub', mockUser.github!),
      ('Figma', mockUser.figma!),
      ('Swagger', mockUser.swagger!),
    ]) {
      expect(find.widgetWithText(TextFormField, value), findsOneWidget, reason: label);
    }
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.widgetWithText(TextFormField, mockUser.username),
              matching: find.byType(EditableText),
            ),
          )
          .readOnly,
      isTrue,
    );
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.widgetWithText(TextFormField, mockUser.email),
              matching: find.byType(EditableText),
            ),
          )
          .readOnly,
      isTrue,
    );
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.widgetWithText(TextFormField, mockUser.name!),
              matching: find.byType(EditableText),
            ),
          )
          .readOnly,
      isFalse,
    );
  });

  testWidgets('Save is enabled only once something is edited, and sends only that', (tester) async {
    final (repository, _) = await pump(tester);
    final save = find.widgetWithText(FilledButton, 'Save changes');
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(
      find.widgetWithText(TextFormField, mockUser.swagger!),
      'http://new/swagger',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(repository.lastUpdate?.toJson(), {'swagger': 'http://new/swagger'});
  });
}
