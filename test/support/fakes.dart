import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:leet_block/models/leetcode_stats.dart';
import 'package:leet_block/services/installed_apps_gateway.dart';
import 'package:leet_block/services/leetcode_service.dart';

class FakeHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) _handler;

  FakeHttpClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable([utf8.encode(response.body)]),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }
}

class StubLeetCodeService extends LeetCodeService {
  StubLeetCodeService({DateTime Function()? now})
    : super(
        client: FakeHttpClient((_) async => http.Response('{}', 500)),
        now: now,
      );

  int fetchUserStatsCalls = 0;
  int validateUsernameCalls = 0;
  int fetchDetailedStatsCalls = 0;
  int fetchProblemDetailsCalls = 0;
  String? lastFetchUserStatsUsername;
  String? lastValidateUsername;
  String? lastFetchDetailedStatsUsername;
  String? lastFetchProblemDetailsUrl;

  LeetCodeStats? fetchUserStatsResult;
  (bool, String?) validateUsernameResult = (true, null);
  Map<String, dynamic>? fetchDetailedStatsResult;
  Map<String, String>? fetchProblemDetailsResult;

  @override
  Future<LeetCodeStats?> fetchUserStats(String username) async {
    fetchUserStatsCalls++;
    lastFetchUserStatsUsername = username;
    return fetchUserStatsResult;
  }

  @override
  Future<(bool, String?)> validateUsername(String username) async {
    validateUsernameCalls++;
    lastValidateUsername = username;
    return validateUsernameResult;
  }

  @override
  Future<Map<String, dynamic>?> fetchDetailedStats(String username) async {
    fetchDetailedStatsCalls++;
    lastFetchDetailedStatsUsername = username;
    return fetchDetailedStatsResult;
  }

  @override
  Future<Map<String, String>?> fetchProblemDetails(String url) async {
    fetchProblemDetailsCalls++;
    lastFetchProblemDetailsUrl = url;
    return fetchProblemDetailsResult;
  }
}

class FakeInstalledAppsGateway implements InstalledAppsGateway {
  FakeInstalledAppsGateway({List<InstalledAppEntry>? apps})
    : _apps = apps ?? [];

  final List<InstalledAppEntry> _apps;

  @override
  Future<List<InstalledAppEntry>> getInstalledApps({
    required bool includeSystemApps,
    required bool withIcons,
  }) async {
    return _apps;
  }
}

InstalledAppEntry fakeInstalledApp({
  required String packageName,
  required String name,
  Uint8List? icon,
}) {
  return InstalledAppEntry(packageName: packageName, name: name, icon: icon);
}
