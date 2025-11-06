import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:inclusing_language_flutter/main.dart';

void main() {
  testWidgets('SignLearn app launches', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SignLearnApp());

    // Verify that the app has the SignLearn title
    expect(find.text('SignLearn'), findsOneWidget);
  });
}
