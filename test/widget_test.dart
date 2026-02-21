import 'package:flutter_test/flutter_test.dart';
import 'package:volvo_engine/main.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const Speedometer());

    expect(find.byType(Speedometer), findsOneWidget);
  });
}
