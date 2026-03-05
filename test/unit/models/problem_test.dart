import 'package:flutter_test/flutter_test.dart';
import 'package:leet_block/models/problem.dart';

void main() {
  test('Problem toJson/fromJson roundtrip', () {
    final problem = Problem(
      id: '1',
      title: 'Two Sum',
      difficulty: 'Easy',
      url: 'https://leetcode.com/problems/two-sum/',
      isPremium: false,
      isCompleted: true,
    );

    final parsed = Problem.fromJson(problem.toJson());

    expect(parsed.id, '1');
    expect(parsed.title, 'Two Sum');
    expect(parsed.difficulty, 'Easy');
    expect(parsed.url, 'https://leetcode.com/problems/two-sum/');
    expect(parsed.isPremium, isFalse);
    expect(parsed.isCompleted, isTrue);
  });
}
