import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leetcode_stats.dart';

class LeetCodeService {
  static const String _baseUrl = 'https://leetcode.com/graphql';
  
  /// Fetches user profile and submission stats from LeetCode
  Future<LeetCodeStats?> fetchUserStats(String username) async {
    try {
      final query = '''
        query getUserProfile(\$username: String!) {
          matchedUser(username: \$username) {
            username
            submitStats: submitStatsGlobal {
              acSubmissionNum {
                difficulty
                count
                submissions
              }
            }
          }
          recentAcSubmissionList(username: \$username, limit: 50) {
            id
            title
            timestamp
          }
        }
      ''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Referer': 'https://leetcode.com',
        },
        body: jsonEncode({
          'query': query,
          'variables': {'username': username},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['data']['matchedUser'] == null) {
          return null; // User not found
        }

        final submitStats = data['data']['matchedUser']['submitStats']['acSubmissionNum'] as List;
        final recentSubmissions = data['data']['recentAcSubmissionList'] as List?;
        
        int totalSolved = 0;
        int easySolved = 0;
        int mediumSolved = 0;
        int hardSolved = 0;

        for (var stat in submitStats) {
          final difficulty = stat['difficulty'] as String;
          final count = stat['count'] as int;
          
          switch (difficulty) {
            case 'All':
              totalSolved = count;
              break;
            case 'Easy':
              easySolved = count;
              break;
            case 'Medium':
              mediumSolved = count;
              break;
            case 'Hard':
              hardSolved = count;
              break;
          }
        }

        // Count submissions from today
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        int todaySubmissions = 0;

        if (recentSubmissions != null) {
          for (var submission in recentSubmissions) {
            final timestamp = int.parse(submission['timestamp']);
            final submissionDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
            if (submissionDate.isAfter(todayStart)) {
              todaySubmissions++;
            }
          }
        }

        return LeetCodeStats(
          username: username,
          totalSolved: totalSolved,
          easySolved: easySolved,
          mediumSolved: mediumSolved,
          hardSolved: hardSolved,
          recentSubmissions: todaySubmissions,
          lastFetched: DateTime.now(),
        );
      }
      
      return null;
    } catch (e) {
      print('Error fetching LeetCode stats: $e');
      return null;
    }
  }

  /// Validates if a username exists on LeetCode
  /// Returns a tuple of (isValid, errorMessage)
  Future<(bool, String?)> validateUsername(String username) async {
    try {
      final query = '''
        query getUserProfile(\$username: String!) {
          matchedUser(username: \$username) {
            username
          }
        }
      ''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Referer': 'https://leetcode.com',
          'Origin': 'https://leetcode.com',
        },
        body: jsonEncode({
          'query': query,
          'variables': {'username': username},
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data']['matchedUser'] != null) {
          return (true, null);
        } else {
          return (false, 'Username "$username" not found on LeetCode');
        }
      }
      
      return (false, 'Server error: ${response.statusCode}');
    } on TimeoutException {
      return (false, 'Connection timeout: Please check your internet');
    } on http.ClientException catch (e) {
      print('Network error validating username: $e');
      return (false, 'Network error: Please check your internet connection');
    } catch (e) {
      print('Error validating username: $e');
      return (false, 'Error: ${e.toString()}');
    }
  }

  /// Fetches detailed stats including streak, recent submissions, activity, and skills
  Future<Map<String, dynamic>?> fetchDetailedStats(String username) async {
    try {
      final query = '''
        query getUserProfile(\$username: String!) {
          matchedUser(username: \$username) {
            username
            submitStats: submitStatsGlobal {
              acSubmissionNum {
                difficulty
                count
              }
            }
            userCalendar {
              streak
              totalActiveDays
              submissionCalendar
            }
            tagProblemCounts {
              advanced {
                tagName
                tagSlug
                problemsSolved
              }
              intermediate {
                tagName
                tagSlug
                problemsSolved
              }
              fundamental {
                tagName
                tagSlug
                problemsSolved
              }
            }
          }
          recentAcSubmissionList(username: \$username, limit: 50) {
            id
            title
            timestamp
            lang
            runtime
            memory
            statusDisplay
          }
        }
      ''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Referer': 'https://leetcode.com',
        },
        body: jsonEncode({
          'query': query,
          'variables': {'username': username},
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['data']['matchedUser'] == null) {
          return null;
        }

        final matchedUser = data['data']['matchedUser'];
        final submitStats = matchedUser['submitStats']['acSubmissionNum'] as List;
        final userCalendar = matchedUser['userCalendar'];
        final recentSubmissions = data['data']['recentAcSubmissionList'] as List?;
        
        int totalSolved = 0;
        int easySolved = 0;
        int mediumSolved = 0;
        int hardSolved = 0;

        for (var stat in submitStats) {
          final difficulty = stat['difficulty'] as String;
          final count = stat['count'] as int;
          
          switch (difficulty) {
            case 'All':
              totalSolved = count;
              break;
            case 'Easy':
              easySolved = count;
              break;
            case 'Medium':
              mediumSolved = count;
              break;
            case 'Hard':
              hardSolved = count;
              break;
          }
        }

        // Parse streak data
        final totalActiveDays = userCalendar?['totalActiveDays'] ?? 0;
        final bestStreak = userCalendar?['streak'] ?? 0; // This is the longest streak
        
        // Calculate current streak from submission calendar
        int currentStreak = 0;
        final submissionCalendarStr = userCalendar?['submissionCalendar'] as String?;
        if (submissionCalendarStr != null && submissionCalendarStr.isNotEmpty) {
          try {
            final calendar = jsonDecode(submissionCalendarStr) as Map<String, dynamic>;
            
            // Convert all keys to integers and sort them descending (most recent first)
            final timestamps = calendar.keys
                .map((k) => int.tryParse(k) ?? 0)
                .where((t) => t > 0 && (calendar[t.toString()] as int) > 0)
                .toList()
              ..sort((a, b) => b.compareTo(a));
            
            if (timestamps.isNotEmpty) {
              // Get today's date at midnight UTC
              final now = DateTime.now();
              final todayUtc = DateTime.utc(now.year, now.month, now.day);
              
              // Check if most recent submission is from today or yesterday
              final mostRecentTimestamp = timestamps.first;
              final mostRecentDate = DateTime.fromMillisecondsSinceEpoch(mostRecentTimestamp * 1000, isUtc: true);
              final mostRecentDay = DateTime.utc(mostRecentDate.year, mostRecentDate.month, mostRecentDate.day);
              
              final daysDiff = todayUtc.difference(mostRecentDay).inDays;
              
              // If last submission was more than 1 day ago, streak is broken
              if (daysDiff > 1) {
                currentStreak = 0;
              } else {
                // Count consecutive days from the most recent submission
                DateTime? previousDay;
                for (final ts in timestamps) {
                  final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true);
                  final day = DateTime.utc(date.year, date.month, date.day);
                  
                  if (previousDay == null) {
                    currentStreak = 1;
                    previousDay = day;
                  } else {
                    final diff = previousDay.difference(day).inDays;
                    if (diff == 1) {
                      currentStreak++;
                      previousDay = day;
                    } else if (diff == 0) {
                      // Same day, skip
                      continue;
                    } else {
                      // Gap in streak, stop counting
                      break;
                    }
                  }
                }
              }
            }
          } catch (e) {
            print('Error parsing submission calendar: $e');
            currentStreak = 0;
          }
        }

        // Parse recent submissions
        final List<Map<String, dynamic>> recentProblems = [];
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final weekStart = todayStart.subtract(Duration(days: todayStart.weekday - 1));
        
        // Weekly activity: [Mon, Tue, Wed, Thu, Fri, Sat, Sun]
        final weeklyActivity = List<int>.filled(7, 0);
        int todaySubmissions = 0;

        if (recentSubmissions != null) {
          for (var submission in recentSubmissions) {
            final timestamp = int.parse(submission['timestamp']);
            final submissionDate = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
            
            // Count today's submissions
            if (submissionDate.isAfter(todayStart)) {
              todaySubmissions++;
            }
            
            // Count weekly activity
            if (submissionDate.isAfter(weekStart)) {
              final dayIndex = submissionDate.weekday - 1; // 0 = Monday
              if (dayIndex >= 0 && dayIndex < 7) {
                weeklyActivity[dayIndex]++;
              }
            }
            
            // Add to recent problems list
            recentProblems.add({
              'id': submission['id'],
              'title': submission['title'],
              'timestamp': timestamp,
              'lang': submission['lang'],
              'runtime': submission['runtime'],
              'memory': submission['memory'],
              'statusDisplay': submission['statusDisplay'],
            });
          }
        }

        final stats = LeetCodeStats(
          username: username,
          totalSolved: totalSolved,
          easySolved: easySolved,
          mediumSolved: mediumSolved,
          hardSolved: hardSolved,
          recentSubmissions: todaySubmissions,
          lastFetched: DateTime.now(),
        );

        // Parse skills/tags data
        final tagProblemCounts = matchedUser['tagProblemCounts'];
        final Map<String, List<Map<String, dynamic>>> skills = {
          'advanced': [],
          'intermediate': [],
          'fundamental': [],
        };

        if (tagProblemCounts != null) {
          for (final category in ['advanced', 'intermediate', 'fundamental']) {
            final tags = tagProblemCounts[category] as List?;
            if (tags != null) {
              for (final tag in tags) {
                skills[category]!.add({
                  'name': tag['tagName'],
                  'slug': tag['tagSlug'],
                  'count': tag['problemsSolved'],
                });
              }
            }
          }
        }

        return {
          'stats': stats,
          'streak': currentStreak,
          'maxStreak': bestStreak, // From LeetCode's userCalendar.streak
          'totalActiveDays': totalActiveDays,
          'weeklyActivity': weeklyActivity,
          'recentProblems': recentProblems,
          'skills': skills,
          'submissionCalendar': userCalendar?['submissionCalendar'], // Raw JSON string
        };
      }
      
      return null;
    } catch (e) {
      print('Error fetching detailed LeetCode stats: $e');
      return null;
    }
  }

  /// Fetches the code for a specific submission
  Future<String?> fetchSubmissionCode(String submissionId) async {
    try {
      final query = '''
        query submissionDetails(\$submissionId: Int!) {
          submissionDetails(submissionId: \$submissionId) {
            code
          }
        }
      ''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Referer': 'https://leetcode.com',
        },
        body: jsonEncode({
          'query': query,
          'variables': {'submissionId': int.parse(submissionId)},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['submissionDetails']?['code'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching submission code: $e');
      return null;
    }
  }
}

