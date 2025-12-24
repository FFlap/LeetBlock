/// Represents a single LeetCode problem
class Problem {
  final String id;
  final String title;
  final String difficulty; // Easy, Medium, Hard
  final String url;
  final bool isPremium;
  bool isCompleted;

  Problem({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.url,
    this.isPremium = false,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'difficulty': difficulty,
    'url': url,
    'isPremium': isPremium,
    'isCompleted': isCompleted,
  };

  factory Problem.fromJson(Map<String, dynamic> json) => Problem(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    difficulty: json['difficulty'] ?? 'Medium',
    url: json['url'] ?? '',
    isPremium: json['isPremium'] ?? false,
    isCompleted: json['isCompleted'] ?? false,
  );
}
