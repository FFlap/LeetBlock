import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

import 'package:leet_block/models/leetcode_stats.dart';
import 'package:leet_block/providers/leet_block_provider.dart';
import 'package:leet_block/screens/home_screen.dart';
import 'package:leet_block/screens/statistics_screen.dart';
import 'package:leet_block/services/leetcode_service.dart';

import 'support/provider_harness.dart';
import 'support/waiters.dart';

const _existingUsername = 'cpcs';
const _nonexistentUsername = 'zmkznhdaosiuhdzcxnjznmzzziuasdhihu';
const _runLiveLeetCodeTests = bool.fromEnvironment('RUN_LIVE_LEETCODE_TESTS');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'HomeScreen live fetch loads LeetCode stats for cpcs',
    (tester) async {
      final provider = await createIntegrationProvider(
        leetCodeService: LeetCodeService(),
        initialPrefs: const {
          'leetcode_username': _existingUsername,
          'daily_quota': 1,
        },
      );
      addTearDown(provider.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<LeetBlockProvider>.value(
          value: provider,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      await waitForFinder(
        tester,
        find.byType(HomeScreen),
        description: 'home screen appears',
      );

      await pumpUntil(
        tester,
        () => !provider.isLoading && provider.currentStats != null,
        timeout: const Duration(seconds: 30),
        description: 'live stats fetch to complete',
      );

      final stats = provider.currentStats;
      expect(stats, isNotNull);
      expect(stats!.username, _existingUsername);
      expect(stats.totalSolved, greaterThan(0));

      await tapWhenVisible(
        tester,
        find.byKey(const ValueKey('home_refresh_progress_button')),
        description: 'refresh progress button',
      );

      await pumpUntil(
        tester,
        () => !provider.isLoading && provider.currentStats != null,
        timeout: const Duration(seconds: 30),
        description: 'live refresh fetch to complete',
      );
      expect(provider.error, anyOf(isNull, isEmpty));
    },
    skip: !_runLiveLeetCodeTests,
  );

  testWidgets(
    'StatisticsScreen live fetch loads detailed stats and recent problems for cpcs',
    (tester) async {
      final provider = await createIntegrationProvider(
        leetCodeService: LeetCodeService(),
        initialPrefs: const {'leetcode_username': _existingUsername},
      );
      addTearDown(provider.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<LeetBlockProvider>.value(
          value: provider,
          child: const MaterialApp(home: StatisticsScreen()),
        ),
      );

      await waitForFinder(
        tester,
        find.byType(StatisticsScreen),
        description: 'statistics screen appears',
      );

      await pumpUntil(
        tester,
        () => !provider.isLoading && provider.detailedStats != null,
        timeout: const Duration(seconds: 40),
        description: 'live detailed stats fetch to complete',
      );

      await tapWhenVisible(
        tester,
        find.text('LeetCode'),
        description: 'LeetCode tab',
      );
      await waitForFinder(
        tester,
        find.text('Recent Activity'),
        description: 'recent activity section',
      );

      final detailed = provider.detailedStats;
      expect(detailed, isNotNull);
      expect(detailed!['stats'], isA<LeetCodeStats>());
      final stats = detailed['stats'] as LeetCodeStats;
      expect(stats.username, _existingUsername);

      final recentProblems = detailed['recentProblems'];
      expect(recentProblems, isA<List<dynamic>>());

      if ((recentProblems as List).isEmpty) {
        expect(find.text('No recent activity'), findsOneWidget);
      } else {
        final first = recentProblems.first;
        expect(
          first,
          isA<Map>(),
          reason: 'Recent problem should be a map entry',
        );
        final title = (first as Map)['title']?.toString() ?? '';
        expect(title, isNotEmpty, reason: 'Recent problem should have a title');
        expect(find.text(title), findsOneWidget);
      }
    },
    skip: !_runLiveLeetCodeTests,
  );

  test(
    'LeetCodeService live validation rejects nonexistent username',
    () async {
      final service = LeetCodeService();
      final (isValid, errorMessage) = await service.validateUsername(
        _nonexistentUsername,
      );

      expect(isValid, isFalse);
      expect(errorMessage, isNotNull);
      expect(errorMessage, contains('not found'));
      expect(errorMessage, contains(_nonexistentUsername));

      final stats = await service.fetchUserStats(_nonexistentUsername);
      expect(stats, isNull);
    },
    skip: !_runLiveLeetCodeTests,
  );
}
