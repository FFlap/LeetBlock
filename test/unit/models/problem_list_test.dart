import 'package:flutter_test/flutter_test.dart';
import 'package:leet_block/models/problem.dart';
import 'package:leet_block/models/problem_list.dart';

void main() {
  test('ProblemList orderedCategoryKeys respects categoryOrder', () {
    final list = ProblemList(
      id: 'custom',
      name: 'Custom',
      isCustom: true,
      categoryOrder: ['B', 'A'],
      categories: {
        'A': [Problem(id: '1', title: 'One', difficulty: 'Easy', url: 'u1')],
        'B': [Problem(id: '2', title: 'Two', difficulty: 'Hard', url: 'u2')],
      },
    );

    expect(list.orderedCategoryKeys, ['B', 'A']);
  });

  test('ProblemList sortedCategories sorts problems by difficulty', () {
    final list = ProblemList(
      id: 'custom',
      name: 'Custom',
      categories: {
        'Array': [
          Problem(id: '1', title: 'H', difficulty: 'Hard', url: 'u1'),
          Problem(id: '2', title: 'E', difficulty: 'Easy', url: 'u2'),
          Problem(id: '3', title: 'M', difficulty: 'Medium', url: 'u3'),
        ],
      },
    );

    final sorted = list.sortedCategories['Array']!;
    expect(sorted.map((p) => p.difficulty).toList(), [
      'Easy',
      'Medium',
      'Hard',
    ]);
  });
}
