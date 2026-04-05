import 'package:flutter_test/flutter_test.dart';
import 'package:mintday/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MintDayApp());
    expect(find.byType(MintDayApp), findsOneWidget);
  });
}
