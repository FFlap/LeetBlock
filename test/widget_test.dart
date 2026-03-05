import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leet_block/main.dart';
import 'support/fakes.dart';
import 'support/provider_test_harness.dart';

void main() {
  testWidgets('LeetBlock app boots to setup flow deterministically', (
    WidgetTester tester,
  ) async {
    final provider = await createInitializedProvider(
      leetCodeService: StubLeetCodeService(),
      initialPrefs: const {},
    );

    await tester.pumpWidget(
      LeetBlockApp(provider: provider, autoStartBlockerService: false),
    );

    await tester.pumpAndSettle();

    expect(find.text('LeetBlock'), findsWidgets);
    expect(find.byKey(const ValueKey('setup_username_input')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
