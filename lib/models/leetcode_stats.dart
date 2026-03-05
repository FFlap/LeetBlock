class LeetCodeStats {
  final String username;
  final int totalSolved;
  final int easySolved;
  final int mediumSolved;
  final int hardSolved;
  final int recentSubmissions;
  final DateTime lastFetched;
  final int totalEasy;
  final int totalMedium;
  final int totalHard;

  LeetCodeStats({
    required this.username,
    required this.totalSolved,
    required this.easySolved,
    required this.mediumSolved,
    required this.hardSolved,
    required this.recentSubmissions,
    required this.lastFetched,
    this.totalEasy = 0,
    this.totalMedium = 0,
    this.totalHard = 0,
  });

  factory LeetCodeStats.empty(String username) {
    return LeetCodeStats(
      username: username,
      totalSolved: 0,
      easySolved: 0,
      mediumSolved: 0,
      hardSolved: 0,
      recentSubmissions: 0,
      lastFetched: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'totalSolved': totalSolved,
      'easySolved': easySolved,
      'mediumSolved': mediumSolved,
      'hardSolved': hardSolved,
      'recentSubmissions': recentSubmissions,
      'lastFetched': lastFetched.toIso8601String(),
      'totalEasy': totalEasy,
      'totalMedium': totalMedium,
      'totalHard': totalHard,
    };
  }

  factory LeetCodeStats.fromJson(Map<String, dynamic> json) {
    return LeetCodeStats(
      username: json['username'] ?? '',
      totalSolved: json['totalSolved'] ?? 0,
      easySolved: json['easySolved'] ?? 0,
      mediumSolved: json['mediumSolved'] ?? 0,
      hardSolved: json['hardSolved'] ?? 0,
      recentSubmissions: json['recentSubmissions'] ?? 0,
      lastFetched:
          json['lastFetched'] != null
              ? DateTime.parse(json['lastFetched'])
              : DateTime.now(),
      totalEasy: json['totalEasy'] ?? 0,
      totalMedium: json['totalMedium'] ?? 0,
      totalHard: json['totalHard'] ?? 0,
    );
  }
}

class DailyProgress {
  final DateTime date;
  final int questionsCompletedToday;
  final int dailyQuota;
  final int startOfDayTotal;

  final int manualOffset; // Persists through refreshes
  final int quotaPenalty; // Penalty from usage

  DailyProgress({
    required this.date,
    required this.questionsCompletedToday,
    required this.dailyQuota,
    required this.startOfDayTotal,
    this.manualOffset = 0,
    this.quotaPenalty = 0,
  });

  bool get isQuotaMet => questionsCompletedToday >= (dailyQuota + quotaPenalty);

  /// Returns true if base quota is met (ignoring penalty) - used for weekly goal tracking
  bool get isBaseQuotaMet => questionsCompletedToday >= dailyQuota;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'questionsCompletedToday': questionsCompletedToday,
      'dailyQuota': dailyQuota,
      'startOfDayTotal': startOfDayTotal,
      'manualOffset': manualOffset,
      'quotaPenalty': quotaPenalty,
    };
  }

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    return DailyProgress(
      date: DateTime.parse(json['date']),
      questionsCompletedToday: json['questionsCompletedToday'] ?? 0,
      dailyQuota: json['dailyQuota'] ?? 1,
      startOfDayTotal: json['startOfDayTotal'] ?? 0,
      manualOffset: json['manualOffset'] ?? 0,
      quotaPenalty: json['quotaPenalty'] ?? 0,
    );
  }

  factory DailyProgress.newDay(int quota, int currentTotal, {DateTime? date}) {
    return DailyProgress(
      date: date ?? DateTime.now(),
      questionsCompletedToday: 0,
      dailyQuota: quota,
      startOfDayTotal: currentTotal,
      manualOffset: 0,
      quotaPenalty: 0,
    );
  }

  DailyProgress copyWith({
    DateTime? date,
    int? questionsCompletedToday,
    int? dailyQuota,
    int? startOfDayTotal,
    int? manualOffset,
    int? quotaPenalty,
  }) {
    return DailyProgress(
      date: date ?? this.date,
      questionsCompletedToday:
          questionsCompletedToday ?? this.questionsCompletedToday,
      dailyQuota: dailyQuota ?? this.dailyQuota,
      startOfDayTotal: startOfDayTotal ?? this.startOfDayTotal,
      manualOffset: manualOffset ?? this.manualOffset,
      quotaPenalty: quotaPenalty ?? this.quotaPenalty,
    );
  }
}
