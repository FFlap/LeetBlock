import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:leet_block/models/streak_seed.dart';
import 'package:leet_block/services/storage_service.dart';

Future<StorageService> _buildStorage(Map<String, Object> initialValues) async {
  SharedPreferences.setMockInitialValues(initialValues);
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs: prefs);
  await storage.init();
  return storage;
}

void main() {
  test('malformed JSON getters return safe defaults', () async {
    final storage = await _buildStorage({
      'blocked_apps': '{bad-json',
      'daily_progress': '{bad-json',
      'daily_completion_history': '{bad-json',
      'daily_screen_time_history': '{bad-json',
      'daily_app_usage_history': '{bad-json',
      'last_stats': '{bad-json',
      'streak_seed': '{bad-json',
      'problem_lists': '{bad-json',
      'problem_completion': '{bad-json',
      'study_preferences': '{bad-json',
    });

    expect(storage.getBlockedApps(), isEmpty);
    expect(storage.getDailyProgress(), isNull);
    expect(storage.getDailyCompletionHistory(), isEmpty);
    expect(storage.getDailyScreenTimeHistory(), isEmpty);
    expect(storage.getDailyAppUsageHistory(), isEmpty);
    expect(storage.getLastStats(), isNull);
    expect(storage.getStreakSeed(), isNull);
    expect(storage.getProblemLists(), isEmpty);
    expect(storage.getProblemCompletion(), isEmpty);
    expect(storage.getStudyPreferences()['activeListId'], isNull);
  });

  test('coerces non-ideal completion/screen-time payloads safely', () async {
    final storage = await _buildStorage({
      'daily_completion_history': '{"2026-02-01":"true","2026-02-02":0}',
      'daily_screen_time_history': '{"2026-02-01":"60000","2026-02-02":120000}',
      'daily_app_usage_history':
          '{"2026-02-01":{"com.app":"30000","com.app2":15000}}',
      'problem_completion': '{"k1":"1","k2":false}',
    });

    expect(storage.getDailyCompletionHistory(), {
      '2026-02-01': true,
      '2026-02-02': false,
    });

    expect(storage.getDailyScreenTimeHistory(), {
      '2026-02-01': 60000,
      '2026-02-02': 120000,
    });

    expect(storage.getDailyAppUsageHistory(), {
      '2026-02-01': {'com.app': 30000, 'com.app2': 15000},
    });

    expect(storage.getProblemCompletion(), {'k1': true, 'k2': false});
  });

  test('study preferences default shape is stable', () async {
    final storage = await _buildStorage({});
    final prefs = storage.getStudyPreferences();

    expect(prefs, containsPair('activeListId', isNull));
    expect(prefs, containsPair('selectionMode', 'first'));
  });

  test('streak seed round-trips safely', () async {
    final storage = await _buildStorage({});
    final seed = StreakSeed(
      username: 'alice',
      count: 20,
      date: DateTime(2026, 3, 20, 21, 0),
    );

    await storage.saveStreakSeed(seed);

    final restored = storage.getStreakSeed();
    expect(restored, isNotNull);
    expect(restored!.username, 'alice');
    expect(restored.count, 20);
    expect(restored.date, DateTime(2026, 3, 20, 21, 0));
  });
}
