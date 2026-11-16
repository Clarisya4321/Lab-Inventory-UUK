import 'package:flutter_test/flutter_test.dart';
import 'package:lab_inventory/main.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(const LabInventoryApp());

    expect(find.byType(LabInventoryApp), findsOneWidget);
  });
}
