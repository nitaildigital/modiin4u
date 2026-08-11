import 'package:flutter_test/flutter_test.dart';
import 'package:modiin4u/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const Modiin4uApp());
    await tester.pumpAndSettle();
  });
}
