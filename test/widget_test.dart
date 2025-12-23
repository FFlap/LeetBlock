import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leet_block/main.dart';

void main() {
  testWidgets('LeetBlock app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LeetBlockApp());

    // Verify the app loads with the splash screen
    expect(find.text('LeetBlock'), findsOneWidget);
    expect(find.text('Discipline through code'), findsOneWidget);
  });
}
