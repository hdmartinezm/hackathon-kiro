import 'package:flutter_test/flutter_test.dart';

import 'package:baby_health/main.dart';

void main() {
  testWidgets('App launches with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BabyHealthApp());

    // Verify that splash screen shows BabyHealth branding.
    expect(find.text('BabyHealth'), findsOneWidget);
  });
}
