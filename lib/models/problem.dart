/// Represents a single LeetCode problem
class Problem {
  final String id;
  final String title;
  final String difficulty; // Easy, Medium, Hard
  final String url;
  bool isCompleted;

  Problem({
    required this.id,
    required this.title,
    required this.difficulty,
    required this.url,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'difficulty': difficulty,
    'url': url,
    'isCompleted': isCompleted,
  };

  factory Problem.fromJson(Map<String, dynamic> json) => Problem(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    difficulty: json['difficulty'] ?? 'Medium',
    url: json['url'] ?? '',
    isCompleted: json['isCompleted'] ?? false,
  );
}
