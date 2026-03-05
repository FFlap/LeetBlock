import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:leet_block/models/leetcode_stats.dart';
import 'package:leet_block/providers/leet_block_provider.dart';
import 'package:leet_block/screens/home_screen.dart';

import '../support/fakes.dart';
import '../support/provider_test_harness.dart';

void main() {
  testWidgets('HomeScreen fetches and refreshes stats for cpcs', (
    tester,
  ) async {
    final now = DateTime(2026, 2, 28, 10, 0);
    final fakeService = StubLeetCodeService(now: () => now)
      ..fetchUserStatsResult = LeetCodeStats(
        username: 'cpcs',
        totalSolved: 1234,
        easySolved: 500,
        mediumSolved: 600,
        hardSolved: 134,
        recentSubmissions: 3,
        lastFetched: now,
        totalEasy: 800,
        totalMedium: 1500,
        totalHard: 700,
      );

    final provider = await createInitializedProvider(
      now: () => now,
      leetCodeService: fakeService,
      initialPrefs: const {
        'is_setup_complete': true,
        'leetcode_username': 'cpcs',
        'daily_quota': 10,
      },
    );

    // Ignore initialization fetch to assert page behavior deterministically.
    fakeService.fetchUserStatsCalls = 0;
    fakeService.lastFetchUserStatsUsername = null;

    await tester.pumpWidget(
      ChangeNotifierProvider<LeetBlockProvider>.value(
        value: provider,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(fakeService.fetchUserStatsCalls, greaterThanOrEqualTo(1));
    expect(fakeService.lastFetchUserStatsUsername, 'cpcs');
    expect(find.text('cpcs'), findsOneWidget);

    final callsBeforeRefresh = fakeService.fetchUserStatsCalls;
    await tester.tap(
      find.byKey(const ValueKey('home_refresh_progress_button')),
    );
    await tester.pumpAndSettle();

    expect(fakeService.fetchUserStatsCalls, greaterThan(callsBeforeRefresh));
    expect(fakeService.lastFetchUserStatsUsername, 'cpcs');
  });
}
