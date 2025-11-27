import 'package:flutter_test/flutter_test.dart';

import 'package:inclusing_language_flutter/main.dart';

void main() {
  testWidgets('Inclusign app launches', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const InclusignApp());

    // Verify that the app has the Inclusign title
    expect(find.text('Inclusign'), findsOneWidget);
  });
}
