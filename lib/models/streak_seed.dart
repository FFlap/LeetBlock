class StreakSeed {
  final String username;
  final int count;
  final DateTime date;

  StreakSeed({required this.username, required this.count, required this.date});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'count': count,
      'date': date.toIso8601String(),
    };
  }

  factory StreakSeed.fromJson(Map<String, dynamic> json) {
    return StreakSeed(
      username: json['username']?.toString() ?? '',
      count: json['count'] is num ? (json['count'] as num).toInt() : 0,
      date:
          json['date'] != null
              ? DateTime.parse(json['date'].toString())
              : DateTime.now(),
    );
  }
}
