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

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

