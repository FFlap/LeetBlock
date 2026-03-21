import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:leet_block/models/leetcode_stats.dart';
import 'package:leet_block/models/problem.dart';
import 'package:leet_block/models/problem_list.dart';
import 'package:leet_block/models/streak_seed.dart';
import '../../support/fakes.dart';
import '../../support/platform_channel_mock.dart';
import '../../support/provider_test_harness.dart';

void main() {
  test(
    'fetchStats resets progress on new day before quota short-circuit',
    () async {
      final now = DateTime(2026, 2, 28, 10, 0);
      final yesterday = now.subtract(const Duration(days: 1));

      final fakeService = StubLeetCodeService(now: () => now)
        ..fetchUserStatsResult = null;

      final provider = await createInitializedProvider(
        now: () => now,
        leetCodeService: fakeService,
        initialPrefs: {
          'leetcode_username': 'alice',
          'daily_quota': 1,
          'daily_progress': jsonEncode(
            DailyProgress(
              date: yesterday,
              questionsCompletedToday: 1,
              dailyQuota: 1,
              startOfDayTotal: 10,
            ).toJson(),
          ),
          'last_stats': jsonEncode(
            LeetCodeStats(
              username: 'alice',
              totalSolved: 10,
              easySolved: 5,
              mediumSolved: 4,
              hardSolved: 1,
              recentSubmissions: 0,
              lastFetched: yesterday,
              totalEasy: 800,
              totalMedium: 1500,
              totalHard: 700,
            ).toJson(),
          ),
        },
      );

      fakeService.fetchUserStatsCalls = 0;
      await provider.fetchStats();

      final progress = provider.dailyProgress;
      expect(progress, isNotNull);
      expect(progress!.date.year, now.year);
      expect(progress.date.month, now.month);
      expect(progress.date.day, now.day);
      expect(fakeService.fetchUserStatsCalls, 1);
    },
  );

  test('effective quota and manual offset math remains consistent', () async {
    final now = DateTime(2026, 2, 28, 10, 0);

    final provider = await createInitializedProvider(
      now: () => now,
      leetCodeService: StubLeetCodeService(now: () => now),
      initialPrefs: {
        'daily_quota': 3,
        'daily_progress': jsonEncode(
          DailyProgress(
            date: now,
            questionsCompletedToday: 1,
            dailyQuota: 3,
            startOfDayTotal: 20,
            manualOffset: 0,
            quotaPenalty: 2,
          ).toJson(),
        ),
      },
    );

    expect(provider.effectiveQuota, 5);
    expect(provider.questionsRemaining, 4);

    await provider.adjustCompletedCount(2);
    expect(provider.questionsCompletedToday, 3);
    expect(provider.manualOffset, 2);

    await provider.resetManualOffset();
    expect(provider.questionsCompletedToday, 1);
    expect(provider.manualOffset, 0);
  });

  test('reset clears state and stops blocker service', () async {
    final platformMock = PlatformChannelMock();
    await platformMock.install();

    final now = DateTime(2026, 2, 28, 10, 0);
    final provider = await createInitializedProvider(
      now: () => now,
      leetCodeService: StubLeetCodeService(now: () => now),
      initialPrefs: {
        'leetcode_username': 'alice',
        'daily_quota': 5,
        'block_message': 'FOCUS',
        'strict_mode': true,
        'penalty_enabled': true,
      },
    );

    await provider.reset();

    expect(platformMock.stopServiceCalls, 1);
    expect(provider.username, isEmpty);
    expect(provider.dailyQuota, 1);
    expect(provider.blockMessage, 'LOCK IN');
    expect(provider.strictMode, isFalse);
    expect(provider.penaltyEnabled, isFalse);
    expect(provider.isSetupComplete, isFalse);

    await platformMock.uninstall();
  });

  test('completeSetup seeds app streak from live LeetCode streak', () async {
    final now = DateTime(2026, 3, 20, 20, 0);
    final stats = LeetCodeStats(
      username: 'alice',
      totalSolved: 250,
      easySolved: 100,
      mediumSolved: 120,
      hardSolved: 30,
      recentSubmissions: 0,
      lastFetched: now,
      totalEasy: 800,
      totalMedium: 1500,
      totalHard: 700,
    );

    final fakeService = StubLeetCodeService(now: () => now)
      ..fetchDetailedStatsResult = {
        'stats': stats,
        'streak': 20,
        'recentProblems': const [],
      };

    final provider = await createInitializedProvider(
      now: () => now,
      leetCodeService: fakeService,
      initialPrefs: {
        'leetcode_username': 'alice',
        'last_stats': jsonEncode(stats.toJson()),
      },
    );

    await provider.completeSetup();

    expect(provider.leetcodeStreak, 20);
    expect(provider.appStreak, 20);
    expect(provider.displayStreak, 20);

    final prefs = await SharedPreferences.getInstance();
    final seedJson = prefs.getString('streak_seed');
    expect(seedJson, isNotNull);
    final seed = StreakSeed.fromJson(
      jsonDecode(seedJson!) as Map<String, dynamic>,
    );
    expect(seed.username, 'alice');
    expect(seed.count, 20);
    expect(seed.date.year, now.year);
    expect(seed.date.month, now.month);
    expect(seed.date.day, now.day);
  });

  test(
    'display streak preserves seeded streak before local day ends',
    () async {
      final now = DateTime(2026, 3, 21, 22, 0);
      final provider = await createInitializedProvider(
        now: () => now,
        leetCodeService: StubLeetCodeService(now: () => now),
        initialPrefs: {
          'leetcode_username': 'alice',
          'daily_quota': 1,
          'daily_progress': jsonEncode(
            DailyProgress(
              date: now,
              questionsCompletedToday: 0,
              dailyQuota: 1,
              startOfDayTotal: 250,
            ).toJson(),
          ),
          'streak_seed': jsonEncode(
            StreakSeed(
              username: 'alice',
              count: 20,
              date: now.subtract(const Duration(days: 1)),
            ).toJson(),
          ),
        },
      );

      expect(provider.appStreak, 20);
      expect(provider.displayStreak, 20);
    },
  );

  test(
    'seeded app streak increments across consecutive local completions',
    () async {
      final now = DateTime(2026, 3, 22, 21, 0);
      final provider = await createInitializedProvider(
        now: () => now,
        leetCodeService: StubLeetCodeService(now: () => now),
        initialPrefs: {
          'leetcode_username': 'alice',
          'daily_quota': 1,
          'daily_progress': jsonEncode(
            DailyProgress(
              date: now,
              questionsCompletedToday: 1,
              dailyQuota: 1,
              startOfDayTotal: 250,
            ).toJson(),
          ),
          'daily_completion_history': jsonEncode({
            '2026-03-21': true,
            '2026-03-22': true,
          }),
          'streak_seed': jsonEncode(
            StreakSeed(
              username: 'alice',
              count: 20,
              date: DateTime(2026, 3, 20, 18, 0),
            ).toJson(),
          ),
        },
      );

      expect(provider.appStreak, 22);
      expect(provider.displayStreak, 22);
    },
  );

  test('seeded app streak breaks after a missed local day', () async {
    final now = DateTime(2026, 3, 23, 21, 0);
    final provider = await createInitializedProvider(
      now: () => now,
      leetCodeService: StubLeetCodeService(now: () => now),
      initialPrefs: {
        'leetcode_username': 'alice',
        'daily_quota': 1,
        'daily_progress': jsonEncode(
          DailyProgress(
            date: now,
            questionsCompletedToday: 1,
            dailyQuota: 1,
            startOfDayTotal: 250,
          ).toJson(),
        ),
        'daily_completion_history': jsonEncode({
          '2026-03-21': true,
          '2026-03-22': false,
          '2026-03-23': true,
        }),
        'streak_seed': jsonEncode(
          StreakSeed(
            username: 'alice',
            count: 20,
            date: DateTime(2026, 3, 20, 18, 0),
          ).toJson(),
        ),
      },
    );

    expect(provider.appStreak, 1);
    expect(provider.displayStreak, 1);
  });

  test(
    'display streak uses the larger of app and live LeetCode streak',
    () async {
      final now = DateTime(2026, 3, 22, 21, 0);
      final fakeService = StubLeetCodeService(now: () => now)
        ..fetchDetailedStatsResult = {
          'stats': LeetCodeStats(
            username: 'alice',
            totalSolved: 250,
            easySolved: 100,
            mediumSolved: 120,
            hardSolved: 30,
            recentSubmissions: 1,
            lastFetched: now,
            totalEasy: 800,
            totalMedium: 1500,
            totalHard: 700,
          ),
          'streak': 25,
          'recentProblems': const [],
        };

      final provider = await createInitializedProvider(
        now: () => now,
        leetCodeService: fakeService,
        initialPrefs: {
          'leetcode_username': 'alice',
          'daily_quota': 1,
          'daily_progress': jsonEncode(
            DailyProgress(
              date: now,
              questionsCompletedToday: 1,
              dailyQuota: 1,
              startOfDayTotal: 250,
            ).toJson(),
          ),
          'daily_completion_history': jsonEncode({
            '2026-03-21': true,
            '2026-03-22': true,
          }),
          'streak_seed': jsonEncode(
            StreakSeed(
              username: 'alice',
              count: 20,
              date: DateTime(2026, 3, 20, 18, 0),
            ).toJson(),
          ),
        },
      );

      await provider.fetchDetailedStats();

      expect(provider.appStreak, 22);
      expect(provider.leetcodeStreak, 25);
      expect(provider.displayStreak, 25);
    },
  );

  test('getNextProblemUrl respects unsolvedOnly and skipPremium', () async {
    final now = DateTime(2026, 2, 28, 10, 0);
    final customList = ProblemList(
      id: 'custom',
      name: 'Custom',
      isCustom: true,
      categories: {
        'Array': [
          Problem(
            id: '1',
            title: 'Solved Non Premium',
            difficulty: 'Easy',
            url: 'https://leetcode.com/problems/one/',
            isPremium: false,
          ),
          Problem(
            id: '2',
            title: 'Premium',
            difficulty: 'Easy',
            url: 'https://leetcode.com/problems/two/',
            isPremium: true,
          ),
          Problem(
            id: '3',
            title: 'Candidate',
            difficulty: 'Medium',
            url: 'https://leetcode.com/problems/three/',
            isPremium: false,
          ),
        ],
      },
    );

    final provider = await createInitializedProvider(
      now: () => now,
      leetCodeService: StubLeetCodeService(now: () => now),
      initialPrefs: {
        'problem_lists': jsonEncode([customList.toJson()]),
        'problem_completion': jsonEncode({'custom_1': true}),
        'study_preferences': jsonEncode({
          'activeListId': 'custom',
          'random': false,
          'unsolvedOnly': true,
          'easiestFirst': false,
          'skipPremium': true,
        }),
      },
    );

    expect(
      provider.getNextProblemUrl(),
      'https://leetcode.com/problems/three/',
    );
  });

  test('loadInstalledApps filters noise and persists toggle state', () async {
    final provider = await createInitializedProvider(
      leetCodeService: StubLeetCodeService(),
      installedAppsGateway: FakeInstalledAppsGateway(
        apps: [
          fakeInstalledApp(
            packageName: 'com.example.focusapp',
            name: 'Focus App',
          ),
          fakeInstalledApp(
            packageName: 'com.google.android.youtube',
            name: 'YouTube',
          ),
          fakeInstalledApp(
            packageName: 'com.android.systemui',
            name: 'System UI',
          ),
          fakeInstalledApp(
            packageName: 'com.leetblock.leet_block',
            name: 'LeetBlock',
          ),
        ],
      ),
      initialPrefs: {
        'blocked_apps': jsonEncode([
          {
            'packageName': 'com.example.focusapp',
            'appName': 'Focus App',
            'isBlocked': true,
          },
        ]),
      },
    );

    await provider.loadInstalledApps();

    final packageNames =
        provider.allApps.map((app) => app.packageName).toList();
    expect(packageNames, contains('com.example.focusapp'));
    expect(packageNames, contains('com.google.android.youtube'));
    expect(packageNames, isNot(contains('com.android.systemui')));
    expect(packageNames, isNot(contains('com.leetblock.leet_block')));
    expect(provider.isAppBlocked('com.example.focusapp'), isTrue);

    await provider.toggleAppBlocking('com.example.focusapp');
    expect(provider.isAppBlocked('com.example.focusapp'), isFalse);

    final prefs = await SharedPreferences.getInstance();
    final blockedApps =
        jsonDecode(prefs.getString('blocked_apps') ?? '[]') as List<dynamic>;
    final hasFocusApp = blockedApps.whereType<Map>().any(
      (entry) => entry['packageName'] == 'com.example.focusapp',
    );
    expect(hasFocusApp, isFalse);
  });

  test('fetchAndSyncProblemLists marks solved problems across lists', () async {
    final customListA = ProblemList(
      id: 'custom_a',
      name: 'Custom A',
      isCustom: true,
      categories: {
        'Array': [
          Problem(
            id: '1',
            title: 'Two Sum',
            difficulty: 'Easy',
            url: 'https://leetcode.com/problems/two-sum/',
          ),
        ],
      },
    );
    final customListB = ProblemList(
      id: 'custom_b',
      name: 'Custom B',
      isCustom: true,
      categories: {
        'Array': [
          Problem(
            id: '1',
            title: 'Two Sum',
            difficulty: 'Easy',
            url: 'https://leetcode.com/problems/two-sum/',
          ),
        ],
      },
    );

    final service =
        StubLeetCodeService()
          ..fetchDetailedStatsResult = {
            'recentProblems': [
              {'title': 'Two Sum'},
            ],
          };

    final provider = await createInitializedProvider(
      leetCodeService: service,
      initialPrefs: {
        'leetcode_username': 'alice',
        'problem_lists': jsonEncode([
          customListA.toJson(),
          customListB.toJson(),
        ]),
        'problem_completion': jsonEncode({}),
      },
    );

    await provider.fetchAndSyncProblemLists();

    final prefs = await SharedPreferences.getInstance();
    final completion =
        jsonDecode(prefs.getString('problem_completion') ?? '{}')
            as Map<String, dynamic>;

    expect(completion['custom_a_1'], isTrue);
    expect(completion['custom_b_1'], isTrue);
  });
}
