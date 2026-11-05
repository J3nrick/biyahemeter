import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:biyahe_meter/features/meter/home_screen.dart';

void main() {
  Widget fare(String text) => MaterialApp(
    home: Center(
      child: RollingFare(text: text, style: const TextStyle(fontSize: 20)),
    ),
  );

  String shown(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .where((t) => t.key != null) // skip the invisible width sizers
      .map((t) => t.data)
      .join();

  testWidgets('only changed digits roll, and the result reads right', (
    tester,
  ) async {
    await tester.pumpWidget(fare('₱ 9.99'));
    expect(shown(tester), '₱ 9.99');

    await tester.pumpWidget(fare('₱ 10.00'));
    await tester.pump(const Duration(milliseconds: 100));
    // Mid-roll: old and new digits are both on screen in their slots.
    expect(find.text('9'), findsWidgets);
    expect(find.text('1'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(shown(tester), '₱ 10.00');
  });
}
