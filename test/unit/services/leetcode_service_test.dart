import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:leet_block/services/leetcode_service.dart';
import '../../support/fakes.dart';

void main() {
  test(
    'fetchUserStats parses data and includes midnight submissions',
    () async {
      final now = DateTime(2026, 2, 10, 13, 0);
      final todayStartSeconds =
          DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch ~/
          1000;

      final client = FakeHttpClient((request) async {
        final req = request as http.Request;
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        expect(body['variables']['username'], 'alice');

        final response = {
          'data': {
            'allQuestionsCount': [
              {'difficulty': 'Easy', 'count': 800},
              {'difficulty': 'Medium', 'count': 1600},
              {'difficulty': 'Hard', 'count': 700},
            ],
            'matchedUser': {
              'submitStats': {
                'acSubmissionNum': [
                  {'difficulty': 'All', 'count': 100},
                  {'difficulty': 'Easy', 'count': 40},
                  {'difficulty': 'Medium', 'count': 45},
                  {'difficulty': 'Hard', 'count': 15},
                ],
              },
            },
            'recentAcSubmissionList': [
              {
                'id': '1',
                'title': 'Boundary',
                'timestamp': todayStartSeconds.toString(),
              },
              {
                'id': '2',
                'title': 'Old',
                'timestamp': (todayStartSeconds - 1).toString(),
              },
            ],
          },
        };

        return http.Response(jsonEncode(response), 200);
      });

      final service = LeetCodeService(client: client, now: () => now);
      final stats = await service.fetchUserStats('alice');

      expect(stats, isNotNull);
      expect(stats!.username, 'alice');
      expect(stats.totalSolved, 100);
      expect(stats.easySolved, 40);
      expect(stats.mediumSolved, 45);
      expect(stats.hardSolved, 15);
      expect(stats.recentSubmissions, 1);
      expect(stats.totalEasy, 800);
      expect(stats.totalMedium, 1600);
      expect(stats.totalHard, 700);
    },
  );

  test('validateUsername returns timeout-friendly error', () async {
    final client = FakeHttpClient((_) async {
      throw TimeoutException('timeout');
    });

    final service = LeetCodeService(client: client);
    final (isValid, errorMessage) = await service.validateUsername('alice');

    expect(isValid, isFalse);
    expect(errorMessage, contains('timeout'));
  });

  test('validateUsername returns not-found for nonexistent user', () async {
    const username = 'zmkznhdaosiuhdzcxnjznmzzziuasdhihu';
    final client = FakeHttpClient((request) async {
      final req = request as http.Request;
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      expect(body['variables']['username'], username);
      return http.Response(
        jsonEncode({
          'data': {'matchedUser': null},
        }),
        200,
      );
    });

    final service = LeetCodeService(client: client);
    final (isValid, errorMessage) = await service.validateUsername(username);

    expect(isValid, isFalse);
    expect(errorMessage, contains(username));
    expect(errorMessage, contains('not found'));
  });

  test('fetchSubmissionCode returns null on timeout', () async {
    final client = FakeHttpClient((_) async {
      throw TimeoutException('timeout');
    });

    final service = LeetCodeService(client: client);
    final code = await service.fetchSubmissionCode('1234');

    expect(code, isNull);
  });
}
