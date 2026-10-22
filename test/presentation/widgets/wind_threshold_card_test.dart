import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/presentation/wind_report/wind_report_screen.dart';

void main() {
  Future<List<int>> pump(WidgetTester tester, {int threshold = 300, bool isSaving = false}) async {
    final saved = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WindThresholdCard(
            threshold: threshold,
            isSaving: isSaving,
            onSave: (v) async => saved.add(v),
          ),
        ),
      ),
    );
    return saved;
  }

  bool saveEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed != null;

  testWidgets('shows the threshold in use, and Save is off until it is changed', (tester) async {
    await pump(tester);

    expect(find.widgetWithText(TextFormField, '300'), findsOneWidget);
    expect(find.text('km/h'), findsOneWidget);
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('a valid new value can be saved', (tester) async {
    final saved = await pump(tester);

    await tester.enterText(find.byType(TextFormField), '250');
    await tester.pump();
    expect(saveEnabled(tester), isTrue);
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(saved, [250]);
  });

  testWidgets('0 and 500 are accepted, 501 and an empty box are not', (tester) async {
    await pump(tester);

    for (final (text, ok) in [('0', true), ('500', true), ('501', false), ('', false)]) {
      await tester.enterText(find.byType(TextFormField), text);
      await tester.pump();
      expect(saveEnabled(tester), ok, reason: '"$text"');
    }
    await tester.enterText(find.byType(TextFormField), '501');
    await tester.pump();
    expect(find.text('Enter a whole number from 0 to 500'), findsOneWidget);
  });

  testWidgets('only digits can be typed', (tester) async {
    await pump(tester);

    await tester.enterText(find.byType(TextFormField), '2a5.0-');
    await tester.pump();

    expect(find.widgetWithText(TextFormField, '250'), findsOneWidget);
  });

  testWidgets('Save is off while saving', (tester) async {
    await pump(tester, isSaving: true);

    await tester.enterText(find.byType(TextFormField), '100');
    await tester.pump();

    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('the box follows a new threshold in use when it is not being edited', (tester) async {
    await pump(tester);
    expect(find.widgetWithText(TextFormField, '300'), findsOneWidget);

    await pump(tester, threshold: 120);

    expect(find.widgetWithText(TextFormField, '120'), findsOneWidget);
  });
}
