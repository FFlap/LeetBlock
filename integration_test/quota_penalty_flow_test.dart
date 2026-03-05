import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:leet_block/main.dart';
import 'package:leet_block/models/leetcode_stats.dart';

import 'support/fakes.dart';
import 'support/platform_channel_mock.dart';
import 'support/provider_harness.dart';
import 'support/waiters.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('base quota doubling and penalty quota increase both apply', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final platformMock = PlatformChannelMock();
    await platformMock.install();
    addTearDown(() => platformMock.uninstall());

    final now = DateTime(2026, 2, 28, 10, 0);
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
        'daily_quota': 2,
        'daily_progress': jsonEncode(
          DailyProgress(
            date: now,
            questionsCompletedToday: 1,
            dailyQuota: 2,
            startOfDayTotal: 10,
            quotaPenalty: 0,
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
      find.byKey(const ValueKey('settings_quota_slider')),
      description: 'settings screen',
    );

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('settings_quota_slider')),
    );
    slider.onChanged?.call(4);
    await tester.pump();

    await tapWhenVisible(
      tester,
      find.byIcon(Icons.arrow_back),
      description: 'back from settings',
    );
    await waitForFinder(
      tester,
      find.textContaining('3 more to unlock apps'),
      description: 'updated doubled quota state',
    );

    expect(provider.dailyQuota, 4);
    expect(provider.effectiveQuota, 4);
    expect(find.textContaining('3 more to unlock apps'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'daily_progress',
      jsonEncode(
        DailyProgress(
          date: now,
          questionsCompletedToday: 1,
          dailyQuota: 4,
          startOfDayTotal: 10,
          quotaPenalty: 2,
        ).toJson(),
      ),
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await waitForFinder(
      tester,
      find.textContaining('5 more to unlock apps'),
      description: 'penalty-adjusted quota state',
    );

    expect(provider.effectiveQuota, 6);
    expect(find.textContaining('5 more to unlock apps'), findsOneWidget);
  });
}
