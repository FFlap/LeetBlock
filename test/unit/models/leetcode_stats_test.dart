import 'package:flutter_test/flutter_test.dart';
import 'package:leet_block/models/leetcode_stats.dart';

void main() {
  test('LeetCodeStats toJson/fromJson roundtrip', () {
    final now = DateTime(2026, 2, 20, 12, 30);
    final stats = LeetCodeStats(
      username: 'alice',
      totalSolved: 100,
      easySolved: 40,
      mediumSolved: 45,
      hardSolved: 15,
      recentSubmissions: 3,
      lastFetched: now,
      totalEasy: 900,
      totalMedium: 1500,
      totalHard: 700,
    );

    final json = stats.toJson();
    final parsed = LeetCodeStats.fromJson(json);

    expect(parsed.username, 'alice');
    expect(parsed.totalSolved, 100);
    expect(parsed.easySolved, 40);
    expect(parsed.mediumSolved, 45);
    expect(parsed.hardSolved, 15);
    expect(parsed.recentSubmissions, 3);
    expect(parsed.lastFetched, now);
    expect(parsed.totalEasy, 900);
    expect(parsed.totalMedium, 1500);
    expect(parsed.totalHard, 700);
  });

  test('DailyProgress base quota and effective quota semantics', () {
    final progress = DailyProgress(
      date: DateTime(2026, 2, 1),
      questionsCompletedToday: 3,
      dailyQuota: 2,
      startOfDayTotal: 10,
      manualOffset: 1,
      quotaPenalty: 2,
    );

    expect(progress.isBaseQuotaMet, isTrue);
    expect(progress.isQuotaMet, isFalse);

    final upgraded = progress.copyWith(questionsCompletedToday: 4);
    expect(upgraded.isQuotaMet, isTrue);
  });
}
