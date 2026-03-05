import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leet_block/main.dart';
import '../support/fakes.dart';
import '../support/provider_test_harness.dart';

Future<void> _pumpFrames(
  WidgetTester tester, {
  int count = 10,
  Duration step = const Duration(milliseconds: 100),
}) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(step);
  }
}

void main() {
  testWidgets('AppRouter auto-starts blocker service once when ready', (
    tester,
  ) async {
    final provider = await createInitializedProvider(
      leetCodeService: StubLeetCodeService(),
      initialPrefs: const {
        'is_setup_complete': true,
        'leetcode_username': 'alice',
      },
    );

    var startCalls = 0;
    await tester.pumpWidget(
      LeetBlockApp(
        provider: provider,
        isAndroid: () => true,
        hasAllPermissions: () async => true,
        startBlockerService: () async {
          startCalls++;
          return true;
        },
      ),
    );

    await _pumpFrames(tester, count: 15);
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(startCalls, 1);

    await _pumpFrames(tester, count: 5);
    expect(startCalls, 1);
  });

  testWidgets('AppRouter does not auto-start before setup completion', (
    tester,
  ) async {
    final provider = await createInitializedProvider(
      leetCodeService: StubLeetCodeService(),
      initialPrefs: const {},
    );

    var startCalls = 0;
    await tester.pumpWidget(
      LeetBlockApp(
        provider: provider,
        isAndroid: () => true,
        hasAllPermissions: () async => true,
        startBlockerService: () async {
          startCalls++;
          return true;
        },
      ),
    );

    await _pumpFrames(tester, count: 10);
    expect(find.byKey(const ValueKey('setup_username_input')), findsOneWidget);
    expect(startCalls, 0);
  });
}
