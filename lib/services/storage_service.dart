import 'dart:convert';
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

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> reload() async {
    await _prefs.reload();
  }

  // Username
  Future<void> saveUsername(String username) async {
    await _prefs.setString(_usernameKey, username);
  }

  String? getUsername() {
    return _prefs.getString(_usernameKey);
  }

  // Daily Quota
  Future<void> saveDailyQuota(int quota) async {
    await _prefs.setInt(_dailyQuotaKey, quota);
  }

  int getDailyQuota() {
    return _prefs.getInt(_dailyQuotaKey) ?? 1;
  }

  // Blocked Apps
  Future<void> saveBlockedApps(List<BlockedAppInfo> apps) async {
    final blockedOnly = apps.where((app) => app.isBlocked).toList();
    final jsonList = blockedOnly.map((app) => app.toJson()).toList();
    await _prefs.setString(_blockedAppsKey, jsonEncode(jsonList));
  }

  List<BlockedAppInfo> getBlockedApps() {
    final jsonString = _prefs.getString(_blockedAppsKey);
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => BlockedAppInfo.fromJson(json)).toList();
  }

  Set<String> getBlockedPackageNames() {
    return getBlockedApps().map((app) => app.packageName).toSet();
  }

  // Daily Progress
  Future<void> saveDailyProgress(DailyProgress progress) async {
    await _prefs.setString(_dailyProgressKey, jsonEncode(progress.toJson()));
  }

  DailyProgress? getDailyProgress() {
    final jsonString = _prefs.getString(_dailyProgressKey);
    if (jsonString == null) return null;
    
    return DailyProgress.fromJson(jsonDecode(jsonString));
  }

  // Last Stats (cached)
  Future<void> saveLastStats(LeetCodeStats stats) async {
    await _prefs.setString(_lastStatsKey, jsonEncode(stats.toJson()));
  }

  LeetCodeStats? getLastStats() {
    final jsonString = _prefs.getString(_lastStatsKey);
    if (jsonString == null) return null;
    
    return LeetCodeStats.fromJson(jsonDecode(jsonString));
  }

  // Setup Complete Flag
  Future<void> setSetupComplete(bool complete) async {
    await _prefs.setBool(_isSetupCompleteKey, complete);
  }

  bool isSetupComplete() {
    return _prefs.getBool(_isSetupCompleteKey) ?? false;
  }

  // Block Message
  Future<void> saveBlockMessage(String message) async {
    await _prefs.setString(_blockMessageKey, message);
  }

  String getBlockMessage() {
    return _prefs.getString(_blockMessageKey) ?? 'LOCK IN';
  }

  // Strict Mode
  Future<void> saveStrictMode(bool enabled) async {
    await _prefs.setBool(_strictModeKey, enabled);
  }

  bool getStrictMode() {
    return _prefs.getBool(_strictModeKey) ?? false;
  }

  // Penalty Settings
  Future<void> savePenaltyEnabled(bool enabled) async {
    await _prefs.setBool(_penaltyEnabledKey, enabled);
  }

  bool getPenaltyEnabled() {
    return _prefs.getBool(_penaltyEnabledKey) ?? false;
  }

  Future<void> savePenaltyThreshold(int minutes) async {
    await _prefs.setInt(_penaltyThresholdKey, minutes);
  }

  int getPenaltyThreshold() {
    return _prefs.getInt(_penaltyThresholdKey) ?? 30; // Default 30 mins
  }

  Future<void> savePenaltyIncrement(int amount) async {
    await _prefs.setInt(_penaltyIncrementKey, amount);
  }

  int getPenaltyIncrement() {
    return _prefs.getInt(_penaltyIncrementKey) ?? 1; // Default 1 question
  }

  // Total Blocked Time (Read-only from native)
  int getTotalBlockedTime() {
    return _prefs.getInt(_totalBlockedTimeKey) ?? 0;
  }

  // Problem Lists
  static const String _problemListsKey = 'problem_lists';
  static const String _problemCompletionKey = 'problem_completion';

  Future<void> saveProblemLists(List<Map<String, dynamic>> lists) async {
    await _prefs.setString(_problemListsKey, jsonEncode(lists));
  }

  List<Map<String, dynamic>> getProblemLists() {
    final jsonString = _prefs.getString(_problemListsKey);
    if (jsonString == null) return [];
    final decoded = jsonDecode(jsonString) as List;
    return decoded.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<void> saveProblemCompletion(Map<String, bool> completion) async {
    await _prefs.setString(_problemCompletionKey, jsonEncode(completion));
  }

  Map<String, bool> getProblemCompletion() {
    final jsonString = _prefs.getString(_problemCompletionKey);
    if (jsonString == null) return {};
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v as bool));
  }

  // Study Preferences
  static const String _studyPreferencesKey = 'study_preferences';

  Future<void> saveStudyPreferences(Map<String, dynamic> prefs) async {
    await _prefs.setString(_studyPreferencesKey, jsonEncode(prefs));
  }

  Map<String, dynamic> getStudyPreferences() {
    final jsonString = _prefs.getString(_studyPreferencesKey);
    if (jsonString == null) {
      return {
        'activeListId': null,
        'selectionMode': 'first', // 'first', 'easiest', 'random'
      };
    }
    return Map<String, dynamic>.from(jsonDecode(jsonString) as Map);
  }

  // Cache default lists for native code to read
  static const String _cachedDefaultListsKey = 'cached_default_lists';

  Future<void> cacheDefaultLists(Map<String, Map<String, dynamic>> lists) async {
    await _prefs.setString(_cachedDefaultListsKey, jsonEncode(lists));
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

