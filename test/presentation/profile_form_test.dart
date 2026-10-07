import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/core/base/result.dart';
import 'package:gp1/data/models/dto/update_profile_request.dart';
import 'package:gp1/data/models/user.dart';
import 'package:gp1/presentation/auth/cubit/auth_cubit.dart';
import 'package:gp1/presentation/profile/cubit/profile_cubit.dart';
import 'package:gp1/presentation/profile/widgets/profile_action_section.dart';

import '../helpers/fakes.dart';
import '../helpers/fixtures.dart';

class _Repository extends FakeAuthRepository {
  UpdateProfileRequest? lastUpdate;

  @override
  Future<Result<User>> updateProfile(UpdateProfileRequest request) async {
    lastUpdate = request;
    return profileResult;
  }
}

void main() {
  Future<(_Repository, AuthCubit)> pump(WidgetTester tester, {bool withUser = true}) async {
    final repository = _Repository();
    final auth = AuthCubit(repository, InMemoryLocalDataBase());
    if (withUser) auth.updateUser(sampleUser);
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: auth),
            BlocProvider(create: (_) => ProfileCubit(repository, auth)),
          ],
          child: const Scaffold(body: CustomScrollView(slivers: [ProfileActionSection()])),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (repository, auth);
  }

  testWidgets('shows every profile field; the username and email are read only', (tester) async {
    await pump(tester);

    for (final (label, value) in [
      ('Username', sampleUser.username),
      ('Email', sampleUser.email),
      ('Full name', sampleUser.name!),
      ('Phone', sampleUser.phone!),
      ('GitHub', sampleUser.github!),
      ('Figma', sampleUser.figma!),
      ('Swagger', sampleUser.swagger!),
    ]) {
      expect(find.widgetWithText(TextFormField, value), findsOneWidget, reason: label);
    }
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: find.widgetWithText(TextFormField, sampleUser.username),
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
              of: find.widgetWithText(TextFormField, sampleUser.email),
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
              of: find.widgetWithText(TextFormField, sampleUser.name!),
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
      find.widgetWithText(TextFormField, sampleUser.swagger!),
      'http://new/swagger',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);

    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(repository.lastUpdate?.toJson(), {'swagger': 'http://new/swagger'});
  });

  testWidgets('fills the form when the profile arrives after the screen is shown', (tester) async {
    final (_, auth) = await pump(tester, withUser: false);
    expect(find.widgetWithText(TextFormField, sampleUser.swagger!), findsNothing);

    auth.updateUser(sampleUser);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, sampleUser.swagger!), findsOneWidget);
    expect(find.widgetWithText(TextFormField, sampleUser.name!), findsOneWidget);
    expect(find.widgetWithText(TextFormField, sampleUser.username), findsOneWidget);
  });
}
