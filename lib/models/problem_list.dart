import 'problem.dart';

/// Represents a collection of problems organized by algorithm category
class ProblemList {
  final String id;
  String name;
  final bool isCustom;
  final Map<String, List<Problem>> categories;
  List<String>? categoryOrder; // For custom lists to track category order

  ProblemList({
    required this.id,
    required this.name,
    this.isCustom = false,
    required this.categories,
    this.categoryOrder,
  });

  int get totalProblems {
    int count = 0;
    for (final problems in categories.values) {
      count += problems.length;
    }
    return count;
  }

  int get completedProblems {
    int count = 0;
    for (final problems in categories.values) {
      count += problems.where((p) => p.isCompleted).length;
    }
    return count;
  }

  /// Returns the ordered list of category names
  List<String> get orderedCategoryKeys {
    if (categoryOrder != null && categoryOrder!.isNotEmpty) {
      // Return in custom order, adding any new categories at the end
      final result = <String>[];
      for (final key in categoryOrder!) {
        if (categories.containsKey(key)) {
          result.add(key);
        }
      }
      // Add any categories not in the order list
      for (final key in categories.keys) {
        if (!result.contains(key)) {
          result.add(key);
        }
      }
      return result;
    }
    return categories.keys.toList();
  }

  /// Returns categories with problems sorted by difficulty (Easy → Medium → Hard)
  Map<String, List<Problem>> get sortedCategories {
    final sorted = <String, List<Problem>>{};
    for (final key in orderedCategoryKeys) {
      if (categories.containsKey(key)) {
        final problems = List<Problem>.from(categories[key]!);
        problems.sort((a, b) {
          const order = {'Easy': 0, 'Medium': 1, 'Hard': 2};
          return (order[a.difficulty] ?? 3).compareTo(order[b.difficulty] ?? 3);
        });
        sorted[key] = problems;
      }
    }
    return sorted;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isCustom': isCustom,
    'categoryOrder': categoryOrder,
    'categories': categories.map(
      (key, value) => MapEntry(key, value.map((p) => p.toJson()).toList()),
    ),
  };

  factory ProblemList.fromJson(Map<String, dynamic> json) {
    final categoriesJson = json['categories'] as Map<String, dynamic>? ?? {};
    final categories = <String, List<Problem>>{};
    
    categoriesJson.forEach((key, value) {
      final problemsList = (value as List)
          .map((p) => Problem.fromJson(p as Map<String, dynamic>))
          .toList();
      categories[key] = problemsList;
    });

    final categoryOrderJson = json['categoryOrder'] as List<dynamic>?;
    final categoryOrder = categoryOrderJson?.cast<String>();

    return ProblemList(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      isCustom: json['isCustom'] ?? false,
      categories: categories,
      categoryOrder: categoryOrder,
    );
  }
}

/// Default problem lists
class DefaultProblemLists {
  static ProblemList get blind75 => ProblemList(
    id: 'blind75',
    name: 'Blind 75',
    isCustom: false,
    categories: {
      'Array': [
        Problem(id: '1', title: 'Two Sum', difficulty: 'Easy', url: 'https://leetcode.com/problems/two-sum/'),
        Problem(id: '121', title: 'Best Time to Buy and Sell Stock', difficulty: 'Easy', url: 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/'),
        Problem(id: '217', title: 'Contains Duplicate', difficulty: 'Easy', url: 'https://leetcode.com/problems/contains-duplicate/'),
        Problem(id: '238', title: 'Product of Array Except Self', difficulty: 'Medium', url: 'https://leetcode.com/problems/product-of-array-except-self/'),
        Problem(id: '53', title: 'Maximum Subarray', difficulty: 'Medium', url: 'https://leetcode.com/problems/maximum-subarray/'),
        Problem(id: '152', title: 'Maximum Product Subarray', difficulty: 'Medium', url: 'https://leetcode.com/problems/maximum-product-subarray/'),
        Problem(id: '153', title: 'Find Minimum in Rotated Sorted Array', difficulty: 'Medium', url: 'https://leetcode.com/problems/find-minimum-in-rotated-sorted-array/'),
        Problem(id: '33', title: 'Search in Rotated Sorted Array', difficulty: 'Medium', url: 'https://leetcode.com/problems/search-in-rotated-sorted-array/'),
        Problem(id: '15', title: '3 Sum', difficulty: 'Medium', url: 'https://leetcode.com/problems/3sum/'),
        Problem(id: '11', title: 'Container With Most Water', difficulty: 'Medium', url: 'https://leetcode.com/problems/container-with-most-water/'),
      ],
      'Binary': [
        Problem(id: '371', title: 'Sum of Two Integers', difficulty: 'Medium', url: 'https://leetcode.com/problems/sum-of-two-integers/'),
        Problem(id: '191', title: 'Number of 1 Bits', difficulty: 'Easy', url: 'https://leetcode.com/problems/number-of-1-bits/'),
        Problem(id: '338', title: 'Counting Bits', difficulty: 'Easy', url: 'https://leetcode.com/problems/counting-bits/'),
        Problem(id: '268', title: 'Missing Number', difficulty: 'Easy', url: 'https://leetcode.com/problems/missing-number/'),
        Problem(id: '190', title: 'Reverse Bits', difficulty: 'Easy', url: 'https://leetcode.com/problems/reverse-bits/'),
      ],
      'Dynamic Programming': [
        Problem(id: '70', title: 'Climbing Stairs', difficulty: 'Easy', url: 'https://leetcode.com/problems/climbing-stairs/'),
        Problem(id: '322', title: 'Coin Change', difficulty: 'Medium', url: 'https://leetcode.com/problems/coin-change/'),
        Problem(id: '300', title: 'Longest Increasing Subsequence', difficulty: 'Medium', url: 'https://leetcode.com/problems/longest-increasing-subsequence/'),
        Problem(id: '1143', title: 'Longest Common Subsequence', difficulty: 'Medium', url: 'https://leetcode.com/problems/longest-common-subsequence/'),
        Problem(id: '139', title: 'Word Break', difficulty: 'Medium', url: 'https://leetcode.com/problems/word-break/'),
        Problem(id: '39', title: 'Combination Sum', difficulty: 'Medium', url: 'https://leetcode.com/problems/combination-sum/'),
        Problem(id: '198', title: 'House Robber', difficulty: 'Medium', url: 'https://leetcode.com/problems/house-robber/'),
        Problem(id: '213', title: 'House Robber II', difficulty: 'Medium', url: 'https://leetcode.com/problems/house-robber-ii/'),
        Problem(id: '91', title: 'Decode Ways', difficulty: 'Medium', url: 'https://leetcode.com/problems/decode-ways/'),
        Problem(id: '62', title: 'Unique Paths', difficulty: 'Medium', url: 'https://leetcode.com/problems/unique-paths/'),
        Problem(id: '55', title: 'Jump Game', difficulty: 'Medium', url: 'https://leetcode.com/problems/jump-game/'),
      ],
      'Graph': [
        Problem(id: '133', title: 'Clone Graph', difficulty: 'Medium', url: 'https://leetcode.com/problems/clone-graph/'),
        Problem(id: '207', title: 'Course Schedule', difficulty: 'Medium', url: 'https://leetcode.com/problems/course-schedule/'),
        Problem(id: '417', title: 'Pacific Atlantic Water Flow', difficulty: 'Medium', url: 'https://leetcode.com/problems/pacific-atlantic-water-flow/'),
        Problem(id: '200', title: 'Number of Islands', difficulty: 'Medium', url: 'https://leetcode.com/problems/number-of-islands/'),
        Problem(id: '128', title: 'Longest Consecutive Sequence', difficulty: 'Medium', url: 'https://leetcode.com/problems/longest-consecutive-sequence/'),
        Problem(id: '269', title: 'Alien Dictionary', difficulty: 'Hard', url: 'https://leetcode.com/problems/alien-dictionary/', isPremium: true),
        Problem(id: '261', title: 'Graph Valid Tree', difficulty: 'Medium', url: 'https://leetcode.com/problems/graph-valid-tree/', isPremium: true),
        Problem(id: '323', title: 'Number of Connected Components', difficulty: 'Medium', url: 'https://leetcode.com/problems/number-of-connected-components-in-an-undirected-graph/', isPremium: true),
      ],
      'Interval': [
        Problem(id: '57', title: 'Insert Interval', difficulty: 'Medium', url: 'https://leetcode.com/problems/insert-interval/'),
        Problem(id: '56', title: 'Merge Intervals', difficulty: 'Medium', url: 'https://leetcode.com/problems/merge-intervals/'),
        Problem(id: '435', title: 'Non-overlapping Intervals', difficulty: 'Medium', url: 'https://leetcode.com/problems/non-overlapping-intervals/'),
        Problem(id: '252', title: 'Meeting Rooms', difficulty: 'Easy', url: 'https://leetcode.com/problems/meeting-rooms/', isPremium: true),
        Problem(id: '253', title: 'Meeting Rooms II', difficulty: 'Medium', url: 'https://leetcode.com/problems/meeting-rooms-ii/', isPremium: true),
      ],
      'Linked List': [
        Problem(id: '206', title: 'Reverse a Linked List', difficulty: 'Easy', url: 'https://leetcode.com/problems/reverse-linked-list/'),
        Problem(id: '141', title: 'Detect Cycle in a Linked List', difficulty: 'Easy', url: 'https://leetcode.com/problems/linked-list-cycle/'),
        Problem(id: '21', title: 'Merge Two Sorted Lists', difficulty: 'Easy', url: 'https://leetcode.com/problems/merge-two-sorted-lists/'),
        Problem(id: '23', title: 'Merge K Sorted Lists', difficulty: 'Hard', url: 'https://leetcode.com/problems/merge-k-sorted-lists/'),
        Problem(id: '19', title: 'Remove Nth Node From End Of List', difficulty: 'Medium', url: 'https://leetcode.com/problems/remove-nth-node-from-end-of-list/'),
        Problem(id: '143', title: 'Reorder List', difficulty: 'Medium', url: 'https://leetcode.com/problems/reorder-list/'),
      ],
      'Matrix': [
        Problem(id: '73', title: 'Set Matrix Zeroes', difficulty: 'Medium', url: 'https://leetcode.com/problems/set-matrix-zeroes/'),
        Problem(id: '54', title: 'Spiral Matrix', difficulty: 'Medium', url: 'https://leetcode.com/problems/spiral-matrix/'),
        Problem(id: '48', title: 'Rotate Image', difficulty: 'Medium', url: 'https://leetcode.com/problems/rotate-image/'),
        Problem(id: '79', title: 'Word Search', difficulty: 'Medium', url: 'https://leetcode.com/problems/word-search/'),
      ],
      'String': [
        Problem(id: '3', title: 'Longest Substring Without Repeating Characters', difficulty: 'Medium', url: 'https://leetcode.com/problems/longest-substring-without-repeating-characters/'),
        Problem(id: '424', title: 'Longest Repeating Character Replacement', difficulty: 'Medium', url: 'https://leetcode.com/problems/longest-repeating-character-replacement/'),
        Problem(id: '76', title: 'Minimum Window Substring', difficulty: 'Hard', url: 'https://leetcode.com/problems/minimum-window-substring/'),
        Problem(id: '242', title: 'Valid Anagram', difficulty: 'Easy', url: 'https://leetcode.com/problems/valid-anagram/'),
        Problem(id: '49', title: 'Group Anagrams', difficulty: 'Medium', url: 'https://leetcode.com/problems/group-anagrams/'),
        Problem(id: '20', title: 'Valid Parentheses', difficulty: 'Easy', url: 'https://leetcode.com/problems/valid-parentheses/'),
        Problem(id: '125', title: 'Valid Palindrome', difficulty: 'Easy', url: 'https://leetcode.com/problems/valid-palindrome/'),
        Problem(id: '5', title: 'Longest Palindromic Substring', difficulty: 'Medium', url: 'https://leetcode.com/problems/longest-palindromic-substring/'),
        Problem(id: '647', title: 'Palindromic Substrings', difficulty: 'Medium', url: 'https://leetcode.com/problems/palindromic-substrings/'),
        Problem(id: '271', title: 'Encode and Decode Strings', difficulty: 'Medium', url: 'https://leetcode.com/problems/encode-and-decode-strings/', isPremium: true),
      ],
      'Tree': [
        Problem(id: '104', title: 'Maximum Depth of Binary Tree', difficulty: 'Easy', url: 'https://leetcode.com/problems/maximum-depth-of-binary-tree/'),
        Problem(id: '100', title: 'Same Tree', difficulty: 'Easy', url: 'https://leetcode.com/problems/same-tree/'),
        Problem(id: '226', title: 'Invert/Flip Binary Tree', difficulty: 'Easy', url: 'https://leetcode.com/problems/invert-binary-tree/'),
        Problem(id: '124', title: 'Binary Tree Maximum Path Sum', difficulty: 'Hard', url: 'https://leetcode.com/problems/binary-tree-maximum-path-sum/'),
        Problem(id: '102', title: 'Binary Tree Level Order Traversal', difficulty: 'Medium', url: 'https://leetcode.com/problems/binary-tree-level-order-traversal/'),
        Problem(id: '297', title: 'Serialize and Deserialize Binary Tree', difficulty: 'Hard', url: 'https://leetcode.com/problems/serialize-and-deserialize-binary-tree/'),
        Problem(id: '572', title: 'Subtree of Another Tree', difficulty: 'Easy', url: 'https://leetcode.com/problems/subtree-of-another-tree/'),
        Problem(id: '105', title: 'Construct Binary Tree from Preorder and Inorder', difficulty: 'Medium', url: 'https://leetcode.com/problems/construct-binary-tree-from-preorder-and-inorder-traversal/'),
        Problem(id: '98', title: 'Validate Binary Search Tree', difficulty: 'Medium', url: 'https://leetcode.com/problems/validate-binary-search-tree/'),
        Problem(id: '230', title: 'Kth Smallest Element in a BST', difficulty: 'Medium', url: 'https://leetcode.com/problems/kth-smallest-element-in-a-bst/'),
        Problem(id: '235', title: 'Lowest Common Ancestor of BST', difficulty: 'Medium', url: 'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/'),
        Problem(id: '208', title: 'Implement Trie (Prefix Tree)', difficulty: 'Medium', url: 'https://leetcode.com/problems/implement-trie-prefix-tree/'),
        Problem(id: '211', title: 'Add and Search Word', difficulty: 'Medium', url: 'https://leetcode.com/problems/design-add-and-search-words-data-structure/'),
        Problem(id: '212', title: 'Word Search II', difficulty: 'Hard', url: 'https://leetcode.com/problems/word-search-ii/'),
      ],
      'Heap': [
        Problem(id: '23', title: 'Merge K Sorted Lists', difficulty: 'Hard', url: 'https://leetcode.com/problems/merge-k-sorted-lists/'),
        Problem(id: '347', title: 'Top K Frequent Elements', difficulty: 'Medium', url: 'https://leetcode.com/problems/top-k-frequent-elements/'),
        Problem(id: '295', title: 'Find Median from Data Stream', difficulty: 'Hard', url: 'https://leetcode.com/problems/find-median-from-data-stream/'),
      ],
    },
  );

  static ProblemList get neetcode250 => ProblemList(
    id: 'neetcode250',
    name: 'NeetCode 250',
    isCustom: false,
    categories: {
      'Arrays & Hashing': [
        Problem(id: '1929', title: 'Concatenation of Array', difficulty: 'Easy', url: 'https://leetcode.com/problems/concatenation-of-array/'),
        Problem(id: '217', title: 'Contains Duplicate', difficulty: 'Easy', url: 'https://leetcode.com/problems/contains-duplicate/'),
        Problem(id: '242', title: 'Valid Anagram', difficulty: 'Easy', url: 'https://leetcode.com/problems/valid-anagram/'),
        Problem(id: '1', title: 'Two Sum', difficulty: 'Easy', url: 'https://leetcode.com/problems/two-sum/'),
        Problem(id: '14', title: 'Longest Common Prefix', difficulty: 'Easy', url: 'https://leetcode.com/problems/longest-common-prefix/'),
        Problem(id: '49', title: 'Group Anagrams', difficulty: 'Medium', url: 'https://leetcode.com/problems/group-anagrams/'),
        Problem(id: '27', title: 'Remove Element', difficulty: 'Easy', url: 'https://leetcode.com/problems/remove-element/'),
        Problem(id: '169', title: 'Majority Element', difficulty: 'Easy', url: 'https://leetcode.com/problems/majority-element/'),
        Problem(id: '705', title: 'Design HashSet', difficulty: 'Easy', url: 'https://leetcode.com/problems/design-hashset/'),
        Problem(id: '706', title: 'Design HashMap', difficulty: 'Easy', url: 'https://leetcode.com/problems/design-hashmap/'),
        Problem(id: '912', title: 'Sort an Array', difficulty: 'Medium', url: 'https://leetcode.com/problems/sort-an-array/'),
        Problem(id: '75', title: 'Sort Colors', difficulty: 'Medium', url: 'https://leetcode.com/problems/sort-colors/'),
        Problem(id: '347', title: 'Top K Frequent Elements', difficulty: 'Medium', url: 'https://leetcode.com/problems/top-k-frequent-elements/'),
        Problem(id: '271', title: 'Encode and Decode Strings', difficulty: 'Medium', url: 'https://leetcode.com/problems/encode-and-decode-strings/', isPremium: true),
        Problem(id: '304', title: 'Range Sum Query 2D Immutable', difficulty: 'Medium', url: 'https://leetcode.com/problems/range-sum-query-2d-immutable/'),
        Problem(id: '238', title: 'Product of Array Except Self', difficulty: 'Medium', url: 'https://leetcode.com/problems/product-of-array-except-self/'),
        Problem(id: '36', title: 'Valid Sudoku', difficulty: 'Medium', url: 'https://leetcode.com/problems/valid-sudoku/'),
        Problem(id: '128', title: 'Longest Consecutive Sequence', difficulty: 'Medium', url: 'https://leetcode.com/problems/longest-consecutive-sequence/'),
        Problem(id: '122', title: 'Best Time to Buy And Sell Stock II', difficulty: 'Medium', url: 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock-ii/'),
        Problem(id: '229', title: 'Majority Element II', difficulty: 'Medium', url: 'https://leetcode.com/problems/majority-element-ii/'),
        Problem(id: '560', title: 'Subarray Sum Equals K', difficulty: 'Medium', url: 'https://leetcode.com/problems/subarray-sum-equals-k/'),
        Problem(id: '41', title: 'First Missing Positive', difficulty: 'Hard', url: 'https://leetcode.com/problems/first-missing-positive/'),
      ],
      'Two Pointers': [
        Problem(id: '344', title: 'Reverse String', difficulty: 'Easy', url: 'https://leetcode.com/problems/reverse-string/'),
        Problem(id: '125', title: 'Valid Palindrome', difficulty: 'Easy', url: 'https://leetcode.com/problems/valid-palindrome/'),
        Problem(id: '680', title: 'Valid Palindrome II', difficulty: 'Easy', url: 'https://leetcode.com/problems/valid-palindrome-ii/'),
        Problem(id: '1768', title: 'Merge Strings Alternately', difficulty: 'Easy', url: 'https://leetcode.com/problems/merge-strings-alternately/'),
        Problem(id: '88', title: 'Merge Sorted Array', difficulty: 'Easy', url: 'https://leetcode.com/problems/merge-sorted-array/'),
        Problem(id: '26', title: 'Remove Duplicates From Sorted Array', difficulty: 'Easy', url: 'https://leetcode.com/problems/remove-duplicates-from-sorted-array/'),
        Problem(id: '167', title: 'Two Sum II', difficulty: 'Medium', url: 'https://leetcode.com/problems/two-sum-ii-input-array-is-sorted/'),
        Problem(id: '15', title: '3Sum', difficulty: 'Medium', url: 'https://leetcode.com/problems/3sum/'),
        Problem(id: '18', title: '4Sum', difficulty: 'Medium', url: 'https://leetcode.com/problems/4sum/'),
        Problem(id: '189', title: 'Rotate Array', difficulty: 'Medium', url: 'https://leetcode.com/problems/rotate-array/'),
        Problem(id: '11', title: 'Container With Most Water', difficulty: 'Medium', url: 'https://leetcode.com/problems/container-with-most-water/'),
        Problem(id: '881', title: 'Boats to Save People', difficulty: 'Medium', url: 'https://leetcode.com/problems/boats-to-save-people/'),
        Problem(id: '42', title: 'Trapping Rain Water', difficulty: 'Hard', url: 'https://leetcode.com/problems/trapping-rain-water/'),
      ],
      'Sliding Window': [
        Problem(id: '219', title: 'Contains Duplicate II', difficulty: 'Easy', url: 'https://leetcode.com/problems/contains-duplicate-ii/'),
        Problem(id: '121', title: 'Best Time to Buy And Sell Stock', difficulty: 'Easy', url: 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock/'),
        Problem(id: '3', title: 'Longest Substring Without Repeating Characters', difficulty: 'Medium', url: 'https://leetcode.com/problems/longest-substring-without-repeating-characters/'),
        Problem(id: '424', title: 'Longest Repeating Character Replacement', difficulty: 'Medium', url: 'https://leetcode.com/problems/longest-repeating-character-replacement/'),
        Problem(id: '567', title: 'Permutation In String', difficulty: 'Medium', url: 'https://leetcode.com/problems/permutation-in-string/'),
        Problem(id: '209', title: 'Minimum Size Subarray Sum', difficulty: 'Medium', url: 'https://leetcode.com/problems/minimum-size-subarray-sum/'),
        Problem(id: '658', title: 'Find K Closest Elements', difficulty: 'Medium', url: 'https://leetcode.com/problems/find-k-closest-elements/'),
        Problem(id: '76', title: 'Minimum Window Substring', difficulty: 'Hard', url: 'https://leetcode.com/problems/minimum-window-substring/'),
        Problem(id: '239', title: 'Sliding Window Maximum', difficulty: 'Hard', url: 'https://leetcode.com/problems/sliding-window-maximum/'),
      ],
      'Stack': [
        Problem(id: '682', title: 'Baseball Game', difficulty: 'Easy', url: 'https://leetcode.com/problems/baseball-game/'),
        Problem(id: '20', title: 'Valid Parentheses', difficulty: 'Easy', url: 'https://leetcode.com/problems/valid-parentheses/'),
        Problem(id: '225', title: 'Implement Stack Using Queues', difficulty: 'Easy', url: 'https://leetcode.com/problems/implement-stack-using-queues/'),
        Problem(id: '232', title: 'Implement Queue using Stacks', difficulty: 'Easy', url: 'https://leetcode.com/problems/implement-queue-using-stacks/'),
        Problem(id: '155', title: 'Min Stack', difficulty: 'Medium', url: 'https://leetcode.com/problems/min-stack/'),
        Problem(id: '150', title: 'Evaluate Reverse Polish Notation', difficulty: 'Medium', url: 'https://leetcode.com/problems/evaluate-reverse-polish-notation/'),
        Problem(id: '735', title: 'Asteroid Collision', difficulty: 'Medium', url: 'https://leetcode.com/problems/asteroid-collision/'),
        Problem(id: '739', title: 'Daily Temperatures', difficulty: 'Medium', url: 'https://leetcode.com/problems/daily-temperatures/'),
        Problem(id: '901', title: 'Online Stock Span', difficulty: 'Medium', url: 'https://leetcode.com/problems/online-stock-span/'),
        Problem(id: '853', title: 'Car Fleet', difficulty: 'Medium', url: 'https://leetcode.com/problems/car-fleet/'),
        Problem(id: '71', title: 'Simplify Path', difficulty: 'Medium', url: 'https://leetcode.com/problems/simplify-path/'),
        Problem(id: '394', title: 'Decode String', difficulty: 'Medium', url: 'https://leetcode.com/problems/decode-string/'),
        Problem(id: '895', title: 'Maximum Frequency Stack', difficulty: 'Hard', url: 'https://leetcode.com/problems/maximum-frequency-stack/'),
        Problem(id: '84', title: 'Largest Rectangle In Histogram', difficulty: 'Hard', url: 'https://leetcode.com/problems/largest-rectangle-in-histogram/'),
      ],
      'Binary Search': [
        Problem(id: '704', title: 'Binary Search', difficulty: 'Easy', url: 'https://leetcode.com/problems/binary-search/'),
        Problem(id: '35', title: 'Search Insert Position', difficulty: 'Easy', url: 'https://leetcode.com/problems/search-insert-position/'),
        Problem(id: '374', title: 'Guess Number Higher Or Lower', difficulty: 'Easy', url: 'https://leetcode.com/problems/guess-number-higher-or-lower/'),
        Problem(id: '69', title: 'Sqrt(x)', difficulty: 'Easy', url: 'https://leetcode.com/problems/sqrtx/'),
        Problem(id: '74', title: 'Search a 2D Matrix', difficulty: 'Medium', url: 'https://leetcode.com/problems/search-a-2d-matrix/'),
        Problem(id: '875', title: 'Koko Eating Bananas', difficulty: 'Medium', url: 'https://leetcode.com/problems/koko-eating-bananas/'),
        Problem(id: '1011', title: 'Capacity to Ship Packages Within D Days', difficulty: 'Medium', url: 'https://leetcode.com/problems/capacity-to-ship-packages-within-d-days/'),
        Problem(id: '153', title: 'Find Minimum In Rotated Sorted Array', difficulty: 'Medium', url: 'https://leetcode.com/problems/find-minimum-in-rotated-sorted-array/'),
        Problem(id: '33', title: 'Search In Rotated Sorted Array', difficulty: 'Medium', url: 'https://leetcode.com/problems/search-in-rotated-sorted-array/'),
        Problem(id: '81', title: 'Search In Rotated Sorted Array II', difficulty: 'Medium', url: 'https://leetcode.com/problems/search-in-rotated-sorted-array-ii/'),
        Problem(id: '981', title: 'Time Based Key Value Store', difficulty: 'Medium', url: 'https://leetcode.com/problems/time-based-key-value-store/'),
        Problem(id: '410', title: 'Split Array Largest Sum', difficulty: 'Hard', url: 'https://leetcode.com/problems/split-array-largest-sum/'),
        Problem(id: '4', title: 'Median of Two Sorted Arrays', difficulty: 'Hard', url: 'https://leetcode.com/problems/median-of-two-sorted-arrays/'),
        Problem(id: '1095', title: 'Find in Mountain Array', difficulty: 'Hard', url: 'https://leetcode.com/problems/find-in-mountain-array/'),
      ],
      'Linked List': [
        Problem(id: '206', title: 'Reverse Linked List', difficulty: 'Easy', url: 'https://leetcode.com/problems/reverse-linked-list/'),
        Problem(id: '21', title: 'Merge Two Sorted Lists', difficulty: 'Easy', url: 'https://leetcode.com/problems/merge-two-sorted-lists/'),
        Problem(id: '141', title: 'Linked List Cycle', difficulty: 'Easy', url: 'https://leetcode.com/problems/linked-list-cycle/'),
        Problem(id: '143', title: 'Reorder List', difficulty: 'Medium', url: 'https://leetcode.com/problems/reorder-list/'),
        Problem(id: '19', title: 'Remove Nth Node From End of List', difficulty: 'Medium', url: 'https://leetcode.com/problems/remove-nth-node-from-end-of-list/'),
        Problem(id: '138', title: 'Copy List With Random Pointer', difficulty: 'Medium', url: 'https://leetcode.com/problems/copy-list-with-random-pointer/'),
        Problem(id: '2', title: 'Add Two Numbers', difficulty: 'Medium', url: 'https://leetcode.com/problems/add-two-numbers/'),
        Problem(id: '287', title: 'Find The Duplicate Number', difficulty: 'Medium', url: 'https://leetcode.com/problems/find-the-duplicate-number/'),
        Problem(id: '92', title: 'Reverse Linked List II', difficulty: 'Medium', url: 'https://leetcode.com/problems/reverse-linked-list-ii/'),
        Problem(id: '622', title: 'Design Circular Queue', difficulty: 'Medium', url: 'https://leetcode.com/problems/design-circular-queue/'),
        Problem(id: '146', title: 'LRU Cache', difficulty: 'Medium', url: 'https://leetcode.com/problems/lru-cache/'),
        Problem(id: '460', title: 'LFU Cache', difficulty: 'Hard', url: 'https://leetcode.com/problems/lfu-cache/'),
        Problem(id: '23', title: 'Merge K Sorted Lists', difficulty: 'Hard', url: 'https://leetcode.com/problems/merge-k-sorted-lists/'),
        Problem(id: '25', title: 'Reverse Nodes In K Group', difficulty: 'Hard', url: 'https://leetcode.com/problems/reverse-nodes-in-k-group/'),
      ],
      'Trees': [
        Problem(id: '94', title: 'Binary Tree Inorder Traversal', difficulty: 'Easy', url: 'https://leetcode.com/problems/binary-tree-inorder-traversal/'),
        Problem(id: '144', title: 'Binary Tree Preorder Traversal', difficulty: 'Easy', url: 'https://leetcode.com/problems/binary-tree-preorder-traversal/'),
        Problem(id: '145', title: 'Binary Tree Postorder Traversal', difficulty: 'Easy', url: 'https://leetcode.com/problems/binary-tree-postorder-traversal/'),
        Problem(id: '226', title: 'Invert Binary Tree', difficulty: 'Easy', url: 'https://leetcode.com/problems/invert-binary-tree/'),
        Problem(id: '104', title: 'Maximum Depth of Binary Tree', difficulty: 'Easy', url: 'https://leetcode.com/problems/maximum-depth-of-binary-tree/'),
        Problem(id: '543', title: 'Diameter of Binary Tree', difficulty: 'Easy', url: 'https://leetcode.com/problems/diameter-of-binary-tree/'),
        Problem(id: '110', title: 'Balanced Binary Tree', difficulty: 'Easy', url: 'https://leetcode.com/problems/balanced-binary-tree/'),
        Problem(id: '100', title: 'Same Tree', difficulty: 'Easy', url: 'https://leetcode.com/problems/same-tree/'),
        Problem(id: '572', title: 'Subtree of Another Tree', difficulty: 'Easy', url: 'https://leetcode.com/problems/subtree-of-another-tree/'),
        Problem(id: '235', title: 'Lowest Common Ancestor of a BST', difficulty: 'Medium', url: 'https://leetcode.com/problems/lowest-common-ancestor-of-a-binary-search-tree/'),
        Problem(id: '701', title: 'Insert into a Binary Search Tree', difficulty: 'Medium', url: 'https://leetcode.com/problems/insert-into-a-binary-search-tree/'),
        Problem(id: '450', title: 'Delete Node in a BST', difficulty: 'Medium', url: 'https://leetcode.com/problems/delete-node-in-a-bst/'),
        Problem(id: '102', title: 'Binary Tree Level Order Traversal', difficulty: 'Medium', url: 'https://leetcode.com/problems/binary-tree-level-order-traversal/'),
        Problem(id: '199', title: 'Binary Tree Right Side View', difficulty: 'Medium', url: 'https://leetcode.com/problems/binary-tree-right-side-view/'),
        Problem(id: '427', title: 'Construct Quad Tree', difficulty: 'Medium', url: 'https://leetcode.com/problems/construct-quad-tree/'),
        Problem(id: '1448', title: 'Count Good Nodes In Binary Tree', difficulty: 'Medium', url: 'https://leetcode.com/problems/count-good-nodes-in-binary-tree/'),
        Problem(id: '98', title: 'Validate Binary Search Tree', difficulty: 'Medium', url: 'https://leetcode.com/problems/validate-binary-search-tree/'),
        Problem(id: '230', title: 'Kth Smallest Element In a BST', difficulty: 'Medium', url: 'https://leetcode.com/problems/kth-smallest-element-in-a-bst/'),
        Problem(id: '105', title: 'Construct Binary Tree From Preorder And Inorder', difficulty: 'Medium', url: 'https://leetcode.com/problems/construct-binary-tree-from-preorder-and-inorder-traversal/'),
        Problem(id: '337', title: 'House Robber III', difficulty: 'Medium', url: 'https://leetcode.com/problems/house-robber-iii/'),
        Problem(id: '1325', title: 'Delete Leaves With a Given Value', difficulty: 'Medium', url: 'https://leetcode.com/problems/delete-leaves-with-a-given-value/'),
        Problem(id: '124', title: 'Binary Tree Maximum Path Sum', difficulty: 'Hard', url: 'https://leetcode.com/problems/binary-tree-maximum-path-sum/'),
        Problem(id: '297', title: 'Serialize And Deserialize Binary Tree', difficulty: 'Hard', url: 'https://leetcode.com/problems/serialize-and-deserialize-binary-tree/'),
      ],
      'Heap / Priority Queue': [
        Problem(id: '703', title: 'Kth Largest Element In a Stream', difficulty: 'Easy', url: 'https://leetcode.com/problems/kth-largest-element-in-a-stream/'),
        Problem(id: '1046', title: 'Last Stone Weight', difficulty: 'Easy', url: 'https://leetcode.com/problems/last-stone-weight/'),
        Problem(id: '973', title: 'K Closest Points to Origin', difficulty: 'Medium', url: 'https://leetcode.com/problems/k-closest-points-to-origin/'),
        Problem(id: '215', title: 'Kth Largest Element In An Array', difficulty: 'Medium', url: 'https://leetcode.com/problems/kth-largest-element-in-an-array/'),
        Problem(id: '621', title: 'Task Scheduler', difficulty: 'Medium', url: 'https://leetcode.com/problems/task-scheduler/'),
        Problem(id: '355', title: 'Design Twitter', difficulty: 'Medium', url: 'https://leetcode.com/problems/design-twitter/'),
        Problem(id: '1834', title: 'Single Threaded CPU', difficulty: 'Medium', url: 'https://leetcode.com/problems/single-threaded-cpu/'),
        Problem(id: '767', title: 'Reorganize String', difficulty: 'Medium', url: 'https://leetcode.com/problems/reorganize-string/'),
        Problem(id: '1405', title: 'Longest Happy String', difficulty: 'Medium', url: 'https://leetcode.com/problems/longest-happy-string/'),
        Problem(id: '1094', title: 'Car Pooling', difficulty: 'Medium', url: 'https://leetcode.com/problems/car-pooling/'),
        Problem(id: '295', title: 'Find Median From Data Stream', difficulty: 'Hard', url: 'https://leetcode.com/problems/find-median-from-data-stream/'),
        Problem(id: '502', title: 'IPO', difficulty: 'Hard', url: 'https://leetcode.com/problems/ipo/'),
      ],
      'Backtracking': [
        Problem(id: '1863', title: 'Sum of All Subsets XOR Total', difficulty: 'Easy', url: 'https://leetcode.com/problems/sum-of-all-subset-xor-totals/'),
        Problem(id: '78', title: 'Subsets', difficulty: 'Medium', url: 'https://leetcode.com/problems/subsets/'),
        Problem(id: '39', title: 'Combination Sum', difficulty: 'Medium', url: 'https://leetcode.com/problems/combination-sum/'),
        Problem(id: '40', title: 'Combination Sum II', difficulty: 'Medium', url: 'https://leetcode.com/problems/combination-sum-ii/'),
        Problem(id: '77', title: 'Combinations', difficulty: 'Medium', url: 'https://leetcode.com/problems/combinations/'),
        Problem(id: '46', title: 'Permutations', difficulty: 'Medium', url: 'https://leetcode.com/problems/permutations/'),
        Problem(id: '90', title: 'Subsets II', difficulty: 'Medium', url: 'https://leetcode.com/problems/subsets-ii/'),
        Problem(id: '47', title: 'Permutations II', difficulty: 'Medium', url: 'https://leetcode.com/problems/permutations-ii/'),
        Problem(id: '22', title: 'Generate Parentheses', difficulty: 'Medium', url: 'https://leetcode.com/problems/generate-parentheses/'),
        Problem(id: '79', title: 'Word Search', difficulty: 'Medium', url: 'https://leetcode.com/problems/word-search/'),
        Problem(id: '131', title: 'Palindrome Partitioning', difficulty: 'Medium', url: 'https://leetcode.com/problems/palindrome-partitioning/'),
        Problem(id: '17', title: 'Letter Combinations of a Phone Number', difficulty: 'Medium', url: 'https://leetcode.com/problems/letter-combinations-of-a-phone-number/'),
        Problem(id: '473', title: 'Matchsticks to Square', difficulty: 'Medium', url: 'https://leetcode.com/problems/matchsticks-to-square/'),
        Problem(id: '698', title: 'Partition to K Equal Sum Subsets', difficulty: 'Medium', url: 'https://leetcode.com/problems/partition-to-k-equal-sum-subsets/'),
        Problem(id: '51', title: 'N Queens', difficulty: 'Hard', url: 'https://leetcode.com/problems/n-queens/'),
        Problem(id: '52', title: 'N Queens II', difficulty: 'Hard', url: 'https://leetcode.com/problems/n-queens-ii/'),
        Problem(id: '140', title: 'Word Break II', difficulty: 'Hard', url: 'https://leetcode.com/problems/word-break-ii/'),
      ],
      'Tries': [
        Problem(id: '208', title: 'Implement Trie Prefix Tree', difficulty: 'Medium', url: 'https://leetcode.com/problems/implement-trie-prefix-tree/'),
        Problem(id: '211', title: 'Design Add And Search Words Data Structure', difficulty: 'Medium', url: 'https://leetcode.com/problems/design-add-and-search-words-data-structure/'),
        Problem(id: '2707', title: 'Extra Characters in a String', difficulty: 'Medium', url: 'https://leetcode.com/problems/extra-characters-in-a-string/'),
        Problem(id: '212', title: 'Word Search II', difficulty: 'Hard', url: 'https://leetcode.com/problems/word-search-ii/'),
      ],
      'Graphs': [
        Problem(id: '463', title: 'Island Perimeter', difficulty: 'Easy', url: 'https://leetcode.com/problems/island-perimeter/'),
        Problem(id: '953', title: 'Verifying An Alien Dictionary', difficulty: 'Easy', url: 'https://leetcode.com/problems/verifying-an-alien-dictionary/'),
        Problem(id: '997', title: 'Find the Town Judge', difficulty: 'Easy', url: 'https://leetcode.com/problems/find-the-town-judge/'),
        Problem(id: '200', title: 'Number of Islands', difficulty: 'Medium', url: 'https://leetcode.com/problems/number-of-islands/'),
        Problem(id: '695', title: 'Max Area of Island', difficulty: 'Medium', url: 'https://leetcode.com/problems/max-area-of-island/'),
        Problem(id: '133', title: 'Clone Graph', difficulty: 'Medium', url: 'https://leetcode.com/problems/clone-graph/'),
        Problem(id: '286', title: 'Walls And Gates', difficulty: 'Medium', url: 'https://leetcode.com/problems/walls-and-gates/'),
        Problem(id: '994', title: 'Rotting Oranges', difficulty: 'Medium', url: 'https://leetcode.com/problems/rotting-oranges/'),
        Problem(id: '417', title: 'Pacific Atlantic Water Flow', difficulty: 'Medium', url: 'https://leetcode.com/problems/pacific-atlantic-water-flow/'),
        Problem(id: '130', title: 'Surrounded Regions', difficulty: 'Medium', url: 'https://leetcode.com/problems/surrounded-regions/'),
        Problem(id: '752', title: 'Open The Lock', difficulty: 'Medium', url: 'https://leetcode.com/problems/open-the-lock/'),
        Problem(id: '207', title: 'Course Schedule', difficulty: 'Medium', url: 'https://leetcode.com/problems/course-schedule/'),
        Problem(id: '210', title: 'Course Schedule II', difficulty: 'Medium', url: 'https://leetcode.com/problems/course-schedule-ii/'),
        Problem(id: '261', title: 'Graph Valid Tree', difficulty: 'Medium', url: 'https://leetcode.com/problems/graph-valid-tree/'),
        Problem(id: '1462', title: 'Course Schedule IV', difficulty: 'Medium', url: 'https://leetcode.com/problems/course-schedule-iv/'),
        Problem(id: '323', title: 'Number of Connected Components', difficulty: 'Medium', url: 'https://leetcode.com/problems/number-of-connected-components-in-an-undirected-graph/'),
        Problem(id: '684', title: 'Redundant Connection', difficulty: 'Medium', url: 'https://leetcode.com/problems/redundant-connection/'),
        Problem(id: '721', title: 'Accounts Merge', difficulty: 'Medium', url: 'https://leetcode.com/problems/accounts-merge/'),
        Problem(id: '399', title: 'Evaluate Division', difficulty: 'Medium', url: 'https://leetcode.com/problems/evaluate-division/'),
        Problem(id: '310', title: 'Minimum Height Trees', difficulty: 'Medium', url: 'https://leetcode.com/problems/minimum-height-trees/'),
        Problem(id: '127', title: 'Word Ladder', difficulty: 'Hard', url: 'https://leetcode.com/problems/word-ladder/'),
      ],
      'Advanced Graphs': [
        Problem(id: '1631', title: 'Path with Minimum Effort', difficulty: 'Medium', url: 'https://leetcode.com/problems/path-with-minimum-effort/'),
        Problem(id: '743', title: 'Network Delay Time', difficulty: 'Medium', url: 'https://leetcode.com/problems/network-delay-time/'),
        Problem(id: '332', title: 'Reconstruct Itinerary', difficulty: 'Hard', url: 'https://leetcode.com/problems/reconstruct-itinerary/'),
        Problem(id: '1584', title: 'Min Cost to Connect All Points', difficulty: 'Medium', url: 'https://leetcode.com/problems/min-cost-to-connect-all-points/'),
        Problem(id: '778', title: 'Swim In Rising Water', difficulty: 'Hard', url: 'https://leetcode.com/problems/swim-in-rising-water/'),
        Problem(id: '269', title: 'Alien Dictionary', difficulty: 'Hard', url: 'https://leetcode.com/problems/alien-dictionary/'),
        Problem(id: '787', title: 'Cheapest Flights Within K Stops', difficulty: 'Medium', url: 'https://leetcode.com/problems/cheapest-flights-within-k-stops/'),
        Problem(id: '1489', title: 'Find Critical and Pseudo Critical Edges in MST', difficulty: 'Hard', url: 'https://leetcode.com/problems/find-critical-and-pseudo-critical-edges-in-minimum-spanning-tree/'),
        Problem(id: '2392', title: 'Build a Matrix With Conditions', difficulty: 'Hard', url: 'https://leetcode.com/problems/build-a-matrix-with-conditions/'),
        Problem(id: '2709', title: 'Greatest Common Divisor Traversal', difficulty: 'Hard', url: 'https://leetcode.com/problems/greatest-common-divisor-traversal/'),
      ],
      '1-D Dynamic Programming': [
        Problem(id: '70', title: 'Climbing Stairs', difficulty: 'Easy', url: 'https://leetcode.com/problems/climbing-stairs/'),
        Problem(id: '746', title: 'Min Cost Climbing Stairs', difficulty: 'Easy', url: 'https://leetcode.com/problems/min-cost-climbing-stairs/'),
        Problem(id: '1137', title: 'N-th Tribonacci Number', difficulty: 'Easy', url: 'https://leetcode.com/problems/n-th-tribonacci-number/'),
        Problem(id: '198', title: 'House Robber', difficulty: 'Medium', url: 'https://leetcode.com/problems/house-robber/'),
        Problem(id: '213', title: 'House Robber II', difficulty: 'Medium', url: 'https://leetcode.com/problems/house-robber-ii/'),
        Problem(id: '5', title: 'Longest Palindromic Substring', difficulty: 'Medium', url: 'https://leetcode.com/problems/longest-palindromic-substring/'),
        Problem(id: '647', title: 'Palindromic Substrings', difficulty: 'Medium', url: 'https://leetcode.com/problems/palindromic-substrings/'),
        Problem(id: '91', title: 'Decode Ways', difficulty: 'Medium', url: 'https://leetcode.com/problems/decode-ways/'),
        Problem(id: '322', title: 'Coin Change', difficulty: 'Medium', url: 'https://leetcode.com/problems/coin-change/'),
        Problem(id: '152', title: 'Maximum Product Subarray', difficulty: 'Medium', url: 'https://leetcode.com/problems/maximum-product-subarray/'),
        Problem(id: '139', title: 'Word Break', difficulty: 'Medium', url: 'https://leetcode.com/problems/word-break/'),
        Problem(id: '300', title: 'Longest Increasing Subsequence', difficulty: 'Medium', url: 'https://leetcode.com/problems/longest-increasing-subsequence/'),
        Problem(id: '416', title: 'Partition Equal Subset Sum', difficulty: 'Medium', url: 'https://leetcode.com/problems/partition-equal-subset-sum/'),
        Problem(id: '377', title: 'Combination Sum IV', difficulty: 'Medium', url: 'https://leetcode.com/problems/combination-sum-iv/'),
        Problem(id: '279', title: 'Perfect Squares', difficulty: 'Medium', url: 'https://leetcode.com/problems/perfect-squares/'),
        Problem(id: '343', title: 'Integer Break', difficulty: 'Medium', url: 'https://leetcode.com/problems/integer-break/'),
        Problem(id: '1406', title: 'Stone Game III', difficulty: 'Hard', url: 'https://leetcode.com/problems/stone-game-iii/'),
      ],
      '2-D Dynamic Programming': [
        Problem(id: '62', title: 'Unique Paths', difficulty: 'Medium', url: 'https://leetcode.com/problems/unique-paths/'),
        Problem(id: '63', title: 'Unique Paths II', difficulty: 'Medium', url: 'https://leetcode.com/problems/unique-paths-ii/'),
        Problem(id: '64', title: 'Minimum Path Sum', difficulty: 'Medium', url: 'https://leetcode.com/problems/minimum-path-sum/'),
        Problem(id: '1143', title: 'Longest Common Subsequence', difficulty: 'Medium', url: 'https://leetcode.com/problems/longest-common-subsequence/'),
        Problem(id: '1049', title: 'Last Stone Weight II', difficulty: 'Medium', url: 'https://leetcode.com/problems/last-stone-weight-ii/'),
        Problem(id: '309', title: 'Best Time to Buy And Sell Stock With Cooldown', difficulty: 'Medium', url: 'https://leetcode.com/problems/best-time-to-buy-and-sell-stock-with-cooldown/'),
        Problem(id: '518', title: 'Coin Change II', difficulty: 'Medium', url: 'https://leetcode.com/problems/coin-change-ii/'),
        Problem(id: '494', title: 'Target Sum', difficulty: 'Medium', url: 'https://leetcode.com/problems/target-sum/'),
        Problem(id: '97', title: 'Interleaving String', difficulty: 'Medium', url: 'https://leetcode.com/problems/interleaving-string/'),
        Problem(id: '877', title: 'Stone Game', difficulty: 'Medium', url: 'https://leetcode.com/problems/stone-game/'),
        Problem(id: '1140', title: 'Stone Game II', difficulty: 'Medium', url: 'https://leetcode.com/problems/stone-game-ii/'),
        Problem(id: '329', title: 'Longest Increasing Path In a Matrix', difficulty: 'Hard', url: 'https://leetcode.com/problems/longest-increasing-path-in-a-matrix/'),
        Problem(id: '115', title: 'Distinct Subsequences', difficulty: 'Hard', url: 'https://leetcode.com/problems/distinct-subsequences/'),
        Problem(id: '72', title: 'Edit Distance', difficulty: 'Medium', url: 'https://leetcode.com/problems/edit-distance/'),
        Problem(id: '312', title: 'Burst Balloons', difficulty: 'Hard', url: 'https://leetcode.com/problems/burst-balloons/'),
        Problem(id: '10', title: 'Regular Expression Matching', difficulty: 'Hard', url: 'https://leetcode.com/problems/regular-expression-matching/'),
      ],
      'Greedy': [
        Problem(id: '860', title: 'Lemonade Change', difficulty: 'Easy', url: 'https://leetcode.com/problems/lemonade-change/'),
        Problem(id: '53', title: 'Maximum Subarray', difficulty: 'Medium', url: 'https://leetcode.com/problems/maximum-subarray/'),
        Problem(id: '918', title: 'Maximum Sum Circular Subarray', difficulty: 'Medium', url: 'https://leetcode.com/problems/maximum-sum-circular-subarray/'),
        Problem(id: '978', title: 'Longest Turbulent Subarray', difficulty: 'Medium', url: 'https://leetcode.com/problems/longest-turbulent-subarray/'),
        Problem(id: '55', title: 'Jump Game', difficulty: 'Medium', url: 'https://leetcode.com/problems/jump-game/'),
        Problem(id: '45', title: 'Jump Game II', difficulty: 'Medium', url: 'https://leetcode.com/problems/jump-game-ii/'),
        Problem(id: '1871', title: 'Jump Game VII', difficulty: 'Medium', url: 'https://leetcode.com/problems/jump-game-vii/'),
        Problem(id: '134', title: 'Gas Station', difficulty: 'Medium', url: 'https://leetcode.com/problems/gas-station/'),
        Problem(id: '846', title: 'Hand of Straights', difficulty: 'Medium', url: 'https://leetcode.com/problems/hand-of-straights/'),
        Problem(id: '649', title: 'Dota2 Senate', difficulty: 'Medium', url: 'https://leetcode.com/problems/dota2-senate/'),
        Problem(id: '1899', title: 'Merge Triplets to Form Target Triplet', difficulty: 'Medium', url: 'https://leetcode.com/problems/merge-triplets-to-form-target-triplet/'),
        Problem(id: '763', title: 'Partition Labels', difficulty: 'Medium', url: 'https://leetcode.com/problems/partition-labels/'),
        Problem(id: '678', title: 'Valid Parenthesis String', difficulty: 'Medium', url: 'https://leetcode.com/problems/valid-parenthesis-string/'),
        Problem(id: '135', title: 'Candy', difficulty: 'Hard', url: 'https://leetcode.com/problems/candy/'),
      ],
      'Intervals': [
        Problem(id: '57', title: 'Insert Interval', difficulty: 'Medium', url: 'https://leetcode.com/problems/insert-interval/'),
        Problem(id: '56', title: 'Merge Intervals', difficulty: 'Medium', url: 'https://leetcode.com/problems/merge-intervals/'),
        Problem(id: '435', title: 'Non Overlapping Intervals', difficulty: 'Medium', url: 'https://leetcode.com/problems/non-overlapping-intervals/'),
        Problem(id: '252', title: 'Meeting Rooms', difficulty: 'Easy', url: 'https://leetcode.com/problems/meeting-rooms/', isPremium: true),
        Problem(id: '253', title: 'Meeting Rooms II', difficulty: 'Medium', url: 'https://leetcode.com/problems/meeting-rooms-ii/', isPremium: true),
        Problem(id: '2402', title: 'Meeting Rooms III', difficulty: 'Hard', url: 'https://leetcode.com/problems/meeting-rooms-iii/'),
        Problem(id: '1851', title: 'Minimum Interval to Include Each Query', difficulty: 'Hard', url: 'https://leetcode.com/problems/minimum-interval-to-include-each-query/'),
      ],
      'Math & Geometry': [
        Problem(id: '168', title: 'Excel Sheet Column Title', difficulty: 'Easy', url: 'https://leetcode.com/problems/excel-sheet-column-title/'),
        Problem(id: '1071', title: 'Greatest Common Divisor of Strings', difficulty: 'Easy', url: 'https://leetcode.com/problems/greatest-common-divisor-of-strings/'),
        Problem(id: '2807', title: 'Insert Greatest Common Divisors in Linked List', difficulty: 'Medium', url: 'https://leetcode.com/problems/insert-greatest-common-divisors-in-linked-list/'),
        Problem(id: '867', title: 'Transpose Matrix', difficulty: 'Easy', url: 'https://leetcode.com/problems/transpose-matrix/'),
        Problem(id: '48', title: 'Rotate Image', difficulty: 'Medium', url: 'https://leetcode.com/problems/rotate-image/'),
        Problem(id: '54', title: 'Spiral Matrix', difficulty: 'Medium', url: 'https://leetcode.com/problems/spiral-matrix/'),
        Problem(id: '73', title: 'Set Matrix Zeroes', difficulty: 'Medium', url: 'https://leetcode.com/problems/set-matrix-zeroes/'),
        Problem(id: '202', title: 'Happy Number', difficulty: 'Easy', url: 'https://leetcode.com/problems/happy-number/'),
        Problem(id: '66', title: 'Plus One', difficulty: 'Easy', url: 'https://leetcode.com/problems/plus-one/'),
        Problem(id: '13', title: 'Roman to Integer', difficulty: 'Easy', url: 'https://leetcode.com/problems/roman-to-integer/'),
        Problem(id: '50', title: 'Pow(x, n)', difficulty: 'Medium', url: 'https://leetcode.com/problems/powx-n/'),
        Problem(id: '43', title: 'Multiply Strings', difficulty: 'Medium', url: 'https://leetcode.com/problems/multiply-strings/'),
        Problem(id: '2013', title: 'Detect Squares', difficulty: 'Medium', url: 'https://leetcode.com/problems/detect-squares/'),
      ],
      'Bit Manipulation': [
        Problem(id: '136', title: 'Single Number', difficulty: 'Easy', url: 'https://leetcode.com/problems/single-number/'),
        Problem(id: '191', title: 'Number of 1 Bits', difficulty: 'Easy', url: 'https://leetcode.com/problems/number-of-1-bits/'),
        Problem(id: '338', title: 'Counting Bits', difficulty: 'Easy', url: 'https://leetcode.com/problems/counting-bits/'),
        Problem(id: '67', title: 'Add Binary', difficulty: 'Easy', url: 'https://leetcode.com/problems/add-binary/'),
        Problem(id: '190', title: 'Reverse Bits', difficulty: 'Easy', url: 'https://leetcode.com/problems/reverse-bits/'),
        Problem(id: '268', title: 'Missing Number', difficulty: 'Easy', url: 'https://leetcode.com/problems/missing-number/'),
        Problem(id: '371', title: 'Sum of Two Integers', difficulty: 'Medium', url: 'https://leetcode.com/problems/sum-of-two-integers/'),
        Problem(id: '7', title: 'Reverse Integer', difficulty: 'Medium', url: 'https://leetcode.com/problems/reverse-integer/'),
        Problem(id: '201', title: 'Bitwise AND of Numbers Range', difficulty: 'Medium', url: 'https://leetcode.com/problems/bitwise-and-of-numbers-range/'),
        Problem(id: '3133', title: 'Minimum Array End', difficulty: 'Medium', url: 'https://leetcode.com/problems/minimum-array-end/'),
      ],
    },
  );
}
