import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_info.dart';
import '../models/leetcode_stats.dart';

class StorageService {
  static const String _usernameKey = 'leetcode_username';
  static const String _dailyQuotaKey = 'daily_quota';
  static const String _blockedAppsKey = 'blocked_apps';
  static const String _dailyProgressKey = 'daily_progress';
  static const String _lastStatsKey = 'last_stats';
  static const String _isSetupCompleteKey = 'is_setup_complete';
  static const String _blockMessageKey = 'block_message';
  static const String _strictModeKey = 'strict_mode';
  static const String _penaltyEnabledKey = 'penalty_enabled';
  static const String _penaltyThresholdKey = 'penalty_threshold_mins';

  static const String _penaltyIncrementKey = 'penalty_increment';
  static const String _totalBlockedTimeKey = 'total_blocked_time';

  final SharedPreferences? _providedPrefs;
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  Future<void>? _initFuture;

  StorageService({SharedPreferences? prefs}) : _providedPrefs = prefs {
    if (prefs != null) {
      _prefs = prefs;
      _isInitialized = true;
    }
  }

  Future<void> init() async {
    if (_isInitialized) {
      return;
    }
    if (_initFuture != null) {
      await _initFuture;
      return;
    }

    _initFuture = () async {
      _prefs = _providedPrefs ?? await SharedPreferences.getInstance();
      _isInitialized = true;
    }();

    try {
      await _initFuture;
    } finally {
      _initFuture = null;
    }
  }

  SharedPreferences get _prefsSafe {
    if (!_isInitialized) {
      throw StateError(
        'StorageService is not initialized. Call init() before use, or '
        'provide SharedPreferences via the constructor.',
      );
    }
    return _prefs;
  }

  Future<void> reload() async {
    await _prefsSafe.reload();
  }

  // Username
  Future<void> saveUsername(String username) async {
    await _prefsSafe.setString(_usernameKey, username);
  }

  String? getUsername() {
    return _prefsSafe.getString(_usernameKey);
  }

  // Daily Quota
  Future<void> saveDailyQuota(int quota) async {
    await _prefsSafe.setInt(_dailyQuotaKey, quota);
  }

  int getDailyQuota() {
    return _prefsSafe.getInt(_dailyQuotaKey) ?? 1;
  }

  // Blocked Apps
  Future<void> saveBlockedApps(List<BlockedAppInfo> apps) async {
    final blockedOnly = apps.where((app) => app.isBlocked).toList();
    final jsonList = blockedOnly.map((app) => app.toJson()).toList();
    await _prefsSafe.setString(_blockedAppsKey, jsonEncode(jsonList));
  }

  List<BlockedAppInfo> getBlockedApps() {
    final jsonString = _prefsSafe.getString(_blockedAppsKey);
    if (jsonString == null) return [];

    final decoded = _decodeJson(jsonString);
    if (decoded is! List) {
      return [];
    }

    final blockedApps = <BlockedAppInfo>[];
    for (final json in decoded.whereType<Map>()) {
      try {
        blockedApps.add(
          BlockedAppInfo.fromJson(Map<String, dynamic>.from(json)),
        );
      } catch (_) {
        // Ignore malformed entries and keep valid apps.
      }
    }
    return blockedApps;
  }

  Set<String> getBlockedPackageNames() {
    return getBlockedApps().map((app) => app.packageName).toSet();
  }

  // Daily Progress
  Future<void> saveDailyProgress(DailyProgress progress) async {
    await _prefsSafe.setString(
      _dailyProgressKey,
      jsonEncode(progress.toJson()),
    );
  }

  DailyProgress? getDailyProgress() {
    final jsonString = _prefsSafe.getString(_dailyProgressKey);
    if (jsonString == null) return null;

    final decoded = _decodeJson(jsonString);
    if (decoded is! Map) {
      return null;
    }

    try {
      return DailyProgress.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  // Daily Completion History
  static const String _dailyCompletionHistoryKey = 'daily_completion_history';

  Future<void> saveDailyCompletionHistory(Map<String, bool> history) async {
    await _prefsSafe.setString(_dailyCompletionHistoryKey, jsonEncode(history));
  }

  Map<String, bool> getDailyCompletionHistory() {
    final jsonString = _prefsSafe.getString(_dailyCompletionHistoryKey);
    if (jsonString == null) return {};
    final decoded = _decodeJson(jsonString);
    if (decoded is! Map) {
      return {};
    }

    final result = <String, bool>{};
    for (final entry in decoded.entries) {
      result[entry.key.toString()] = _asBool(entry.value);
    }
    return result;
  }

  // Daily Screen Time History
  static const String _dailyScreenTimeHistoryKey = 'daily_screen_time_history';

  Future<void> saveDailyScreenTimeHistory(Map<String, int> history) async {
    await _prefsSafe.setString(_dailyScreenTimeHistoryKey, jsonEncode(history));
  }

  Map<String, int> getDailyScreenTimeHistory() {
    final jsonString = _prefsSafe.getString(_dailyScreenTimeHistoryKey);
    if (jsonString == null) return {};
    final decoded = _decodeJson(jsonString);
    if (decoded is! Map) {
      return {};
    }

    final result = <String, int>{};
    for (final entry in decoded.entries) {
      result[entry.key.toString()] = _asInt(entry.value);
    }
    return result;
  }

  // Daily App Usage History Data
  static const String _dailyAppUsageHistoryKey = 'daily_app_usage_history';

  Map<String, Map<String, int>> getDailyAppUsageHistory() {
    final jsonString = _prefsSafe.getString(_dailyAppUsageHistoryKey);
    if (jsonString == null) return {};

    final decoded = _decodeJson(jsonString);
    if (decoded is! Map) {
      return {};
    }

    final result = <String, Map<String, int>>{};

    for (final entry in decoded.entries) {
      final date = entry.key.toString();
      final appMap = entry.value;
      if (appMap is! Map) {
        continue;
      }

      final usage = <String, int>{};
      for (final appEntry in appMap.entries) {
        usage[appEntry.key.toString()] = _asInt(appEntry.value);
      }
      result[date] = usage;
    }

    return result;
  }

  // Last Stats (cached)
  Future<void> saveLastStats(LeetCodeStats stats) async {
    await _prefsSafe.setString(_lastStatsKey, jsonEncode(stats.toJson()));
  }

  LeetCodeStats? getLastStats() {
    final jsonString = _prefsSafe.getString(_lastStatsKey);
    if (jsonString == null) return null;

    final decoded = _decodeJson(jsonString);
    if (decoded is! Map) {
      return null;
    }

    try {
      return LeetCodeStats.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  // Setup Complete Flag
  Future<void> setSetupComplete(bool complete) async {
    await _prefsSafe.setBool(_isSetupCompleteKey, complete);
  }

  bool isSetupComplete() {
    return _prefsSafe.getBool(_isSetupCompleteKey) ?? false;
  }

  // Block Message
  Future<void> saveBlockMessage(String message) async {
    await _prefsSafe.setString(_blockMessageKey, message);
  }

  String getBlockMessage() {
    return _prefsSafe.getString(_blockMessageKey) ?? 'LOCK IN';
  }

  // Strict Mode
  Future<void> saveStrictMode(bool enabled) async {
    await _prefsSafe.setBool(_strictModeKey, enabled);
  }

  bool getStrictMode() {
    return _prefsSafe.getBool(_strictModeKey) ?? false;
  }

  // Penalty Settings
  Future<void> savePenaltyEnabled(bool enabled) async {
    await _prefsSafe.setBool(_penaltyEnabledKey, enabled);
  }

  bool getPenaltyEnabled() {
    return _prefsSafe.getBool(_penaltyEnabledKey) ?? false;
  }

  Future<void> savePenaltyThreshold(int minutes) async {
    await _prefsSafe.setInt(_penaltyThresholdKey, minutes);
  }

  int getPenaltyThreshold() {
    return _prefsSafe.getInt(_penaltyThresholdKey) ?? 30; // Default 30 mins
  }

  Future<void> savePenaltyIncrement(int amount) async {
    await _prefsSafe.setInt(_penaltyIncrementKey, amount);
  }

  int getPenaltyIncrement() {
    return _prefsSafe.getInt(_penaltyIncrementKey) ?? 1; // Default 1 question
  }

  // Total Blocked Time (Read-only from native)
  int getTotalBlockedTime() {
    return _prefsSafe.getInt(_totalBlockedTimeKey) ?? 0;
  }

  // Problem Lists
  static const String _problemListsKey = 'problem_lists';
  static const String _problemCompletionKey = 'problem_completion';

  Future<void> saveProblemLists(List<Map<String, dynamic>> lists) async {
    await _prefsSafe.setString(_problemListsKey, jsonEncode(lists));
  }

  List<Map<String, dynamic>> getProblemLists() {
    final jsonString = _prefsSafe.getString(_problemListsKey);
    if (jsonString == null) return [];
    final decoded = _decodeJson(jsonString);
    if (decoded is! List) {
      return [];
    }
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> saveProblemCompletion(Map<String, bool> completion) async {
    await _prefsSafe.setString(_problemCompletionKey, jsonEncode(completion));
  }

  Map<String, bool> getProblemCompletion() {
    final jsonString = _prefsSafe.getString(_problemCompletionKey);
    if (jsonString == null) return {};
    final decoded = _decodeJson(jsonString);
    if (decoded is! Map) {
      return {};
    }

    final result = <String, bool>{};
    for (final entry in decoded.entries) {
      result[entry.key.toString()] = _asBool(entry.value);
    }
    return result;
  }

  // Study Preferences
  static const String _studyPreferencesKey = 'study_preferences';

  Future<void> saveStudyPreferences(Map<String, dynamic> prefs) async {
    await _prefsSafe.setString(_studyPreferencesKey, jsonEncode(prefs));
  }

  Map<String, dynamic> getStudyPreferences() {
    final jsonString = _prefsSafe.getString(_studyPreferencesKey);
    if (jsonString == null) {
      return {
        'activeListId': null,
        'selectionMode': 'first', // 'first', 'easiest', 'random'
      };
    }
    final decoded = _decodeJson(jsonString);
    if (decoded is! Map) {
      return {'activeListId': null, 'selectionMode': 'first'};
    }
    return Map<String, dynamic>.from(decoded);
  }

  // Cache default lists for native code to read
  static const String _cachedDefaultListsKey = 'cached_default_lists';

  Future<void> cacheDefaultLists(
    Map<String, Map<String, dynamic>> lists,
  ) async {
    await _prefsSafe.setString(_cachedDefaultListsKey, jsonEncode(lists));
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefsSafe.clear();
  }

  dynamic _decodeJson(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  bool _asBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == '0') {
        return false;
      }
    }
    return false;
  }
}
