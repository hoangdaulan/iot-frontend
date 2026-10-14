import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gp1/presentation/widgets/timestamp_search_cell.dart';

void main() {
  final timestamp = DateTime(2026, 10, 6, 11, 5, 9);

  Widget host(ValueChanged<String>? onSearch) => MaterialApp(
    home: Scaffold(
      body: TimestampSearchCell(timestamp: timestamp, onSearch: onSearch),
    ),
  );

  testWidgets('the button hands the shown time to onSearch', (tester) async {
    String? searched;
    await tester.pumpWidget(host((text) => searched = text));

    expect(find.text('2026/10/06 11:05:09'), findsOneWidget);
    await tester.tap(find.byType(OutlinedButton));

    expect(searched, '2026/10/06 11:05:09');
  });

  testWidgets('the button is disabled without onSearch', (tester) async {
    await tester.pumpWidget(host(null));

    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed, isNull);
  });
}
