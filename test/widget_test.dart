import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:peelbill/main.dart';

void main() {
  testWidgets('Bill form shows and rejects empty submission', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('New Bill'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Save bill'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save bill'));
    await tester.pump();
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await tester.pump();

    expect(find.text('Enter a title'), findsOneWidget);
  });
}
