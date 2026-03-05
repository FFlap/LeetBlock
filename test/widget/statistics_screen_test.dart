import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:leet_block/models/leetcode_stats.dart';
import 'package:leet_block/providers/leet_block_provider.dart';
import 'package:leet_block/screens/statistics_screen.dart';
import '../support/fakes.dart';
import '../support/provider_test_harness.dart';

void main() {
  testWidgets('StatisticsScreen difficulty progress handles 0 totals safely', (
    tester,
  ) async {
    final now = DateTime(2026, 2, 28, 10, 0);
    final provider = await createInitializedProvider(
      now: () => now,
      leetCodeService: StubLeetCodeService(now: () => now),
      initialPrefs: {
        'leetcode_username': 'alice',
        'last_stats': jsonEncode(
          LeetCodeStats(
            username: 'alice',
            totalSolved: 0,
            easySolved: 0,
            mediumSolved: 0,
            hardSolved: 0,
            recentSubmissions: 0,
            lastFetched: now,
            totalEasy: 0,
            totalMedium: 0,
            totalHard: 0,
          ).toJson(),
        ),
      },
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<LeetBlockProvider>.value(
        value: provider,
        child: const MaterialApp(home: StatisticsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    final indicators = tester.widgetList<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );

    for (final indicator in indicators) {
      final value = indicator.value;
      if (value != null) {
        expect(value.isNaN, isFalse);
      }
    }

    expect(find.byType(StatisticsScreen), findsOneWidget);
  });

  testWidgets(
    'StatisticsScreen fetches detailed stats and recent problems for cpcs',
    (tester) async {
      final now = DateTime(2026, 2, 28, 10, 0);
      final fakeService = StubLeetCodeService(now: () => now)
        ..fetchDetailedStatsResult = {
          'stats': LeetCodeStats(
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
          ),
          'streak': 12,
          'maxStreak': 20,
          'weekSubmissions': List<int>.filled(7, 0),
          'recentProblems': [
            {
              'id': '1',
              'title': 'Two Sum',
              'timestamp':
                  now
                      .subtract(const Duration(hours: 2))
                      .millisecondsSinceEpoch ~/
                  1000,
              'lang': 'dart',
              'runtime': '1 ms',
              'memory': '40 MB',
              'statusDisplay': 'Accepted',
            },
            {
              'id': '2',
              'title': 'Add Two Numbers',
              'timestamp':
                  now
                      .subtract(const Duration(hours: 5))
                      .millisecondsSinceEpoch ~/
                  1000,
              'lang': 'python3',
              'runtime': '60 ms',
              'memory': '45 MB',
              'statusDisplay': 'Accepted',
            },
          ],
          'submissionCalendar': '{}',
        };

      final provider = await createInitializedProvider(
        now: () => now,
        leetCodeService: fakeService,
        initialPrefs: {
          'leetcode_username': 'cpcs',
          'last_stats': jsonEncode(
            LeetCodeStats(
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
            ).toJson(),
          ),
        },
      );

      fakeService.fetchDetailedStatsCalls = 0;
      fakeService.lastFetchDetailedStatsUsername = null;

      await tester.pumpWidget(
        ChangeNotifierProvider<LeetBlockProvider>.value(
          value: provider,
          child: const MaterialApp(home: StatisticsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('LeetCode'));
      await tester.pumpAndSettle();

      expect(fakeService.fetchDetailedStatsCalls, greaterThanOrEqualTo(1));
      expect(fakeService.lastFetchDetailedStatsUsername, 'cpcs');
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Two Sum'), findsOneWidget);
      expect(find.text('Add Two Numbers'), findsOneWidget);
    },
  );
}
