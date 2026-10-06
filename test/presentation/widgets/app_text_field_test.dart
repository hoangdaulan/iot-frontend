import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/presentation/widgets/app_text_field.dart';
import 'package:gp1/presentation/widgets/models/app_option.dart';

void main() {
  group('AppTextField with a controller of the caller', () {
    testWidgets('keeps what is typed when it rebuilds without a value', (tester) async {
      final controller = TextEditingController(text: 'abc');
      addTearDown(controller.dispose);
      late StateSetter rebuild;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return AppTextField(controller: controller);
              },
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'abcdef');
      rebuild(() {});
      await tester.pumpAndSettle();

      expect(controller.text, 'abcdef');
    });

    testWidgets('does not dispose the controller it was given', (tester) async {
      final controller = TextEditingController(text: 'abc');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AppTextField(controller: controller)),
        ),
      );
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));

      // A disposed controller throws on use.
      expect(() => controller.text = 'still usable', returnsNormally);
    });
  });

  testWidgets('without a controller it follows the value it is given', (tester) async {
    Widget field(String value) => MaterialApp(
      home: Scaffold(body: AppTextField(value: value)),
    );

    await tester.pumpWidget(field('one'));
    expect(find.text('one'), findsOneWidget);

    await tester.pumpWidget(field('two'));
    await tester.pumpAndSettle();
    expect(find.text('two'), findsOneWidget);
  });

  test('AppOption options are equal when their values are', () {
    expect(const AppOption<int>(1, 'LED 1'), const AppOption<int>(1, 'renamed'));
    expect(const AppOption<int>(null, 'All Devices'), const AppOption<int>(null, 'All'));
    expect(const AppOption<int>(1, 'LED 1'), isNot(const AppOption<int>(2, 'LED 1')));
    expect(const AppOption<int>(1, 'LED 1').displayText, 'LED 1');
  });
}
