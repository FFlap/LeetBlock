import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:leet_block/main.dart';
import 'package:leet_block/models/leetcode_stats.dart';
import 'package:leet_block/screens/permission_screen.dart';

import 'support/fakes.dart';
import 'support/platform_channel_mock.dart';
import 'support/provider_harness.dart';
import 'support/waiters.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('PermissionScreen grants and completes flow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final platformMock = PlatformChannelMock(
      hasUsageStatsPermission: true,
      hasOverlayPermission: true,
    );
    await platformMock.install();

    var completionCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PermissionScreen(
          onAllPermissionsGranted: () {
            completionCalls++;
          },
        ),
      ),
    );

    await pumpUntil(
      tester,
      () => completionCalls == 1,
      description: 'permission completion callback',
    );

    expect(completionCalls, 1);
    expect(platformMock.startServiceCalls, 1);

    await platformMock.uninstall();
  });

  testWidgets('reset flow returns app to setup state', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime(2026, 2, 28, 10, 0);
    final platformMock = PlatformChannelMock();
    await platformMock.install();

    final provider = await createIntegrationProvider(
      now: () => now,
      leetCodeService: StubLeetCodeService(now: () => now)
        ..fetchUserStatsResult = LeetCodeStats(
          username: 'alice',
          totalSolved: 10,
          easySolved: 4,
          mediumSolved: 4,
          hardSolved: 2,
          recentSubmissions: 1,
          lastFetched: now,
          totalEasy: 100,
          totalMedium: 100,
          totalHard: 100,
        ),
      initialPrefs: {
        'is_setup_complete': true,
        'leetcode_username': 'alice',
        'daily_progress': jsonEncode(
          DailyProgress(
            date: now,
            questionsCompletedToday: 1,
            dailyQuota: 2,
            startOfDayTotal: 10,
          ).toJson(),
        ),
      },
    );

    await tester.pumpWidget(
      LeetBlockApp(provider: provider, autoStartBlockerService: false),
    );
    await waitForFinder(
      tester,
      find.byIcon(Icons.settings_outlined),
      description: 'main shell',
    );

    await tapWhenVisible(
      tester,
      find.byIcon(Icons.settings_outlined),
      description: 'settings tab button',
    );
    await waitForFinder(
      tester,
      find.byKey(const ValueKey('settings_strict_mode_switch')),
      description: 'settings screen',
    );

    await tester.scrollUntilVisible(
      find.text('Reset App'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tapWhenVisible(
      tester,
      find.text('Reset App'),
      description: 'reset app tile',
    );
    await waitForFinder(
      tester,
      find.byKey(const ValueKey('settings_reset_everything_button')),
      description: 'reset confirmation dialog',
    );

    await tester.enterText(find.byType(TextField).last, 'confirm');
    await tapWhenVisible(
      tester,
      find.byKey(const ValueKey('settings_reset_everything_button')),
      description: 'confirm reset',
    );
    await waitForFinder(
      tester,
      find.byKey(const ValueKey('setup_username_input')),
      description: 'setup screen after reset',
    );

    expect(find.byKey(const ValueKey('setup_username_input')), findsOneWidget);
    expect(platformMock.stopServiceCalls, 1);

    await platformMock.uninstall();
  });
}
