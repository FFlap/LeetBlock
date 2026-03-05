import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:leet_block/main.dart';
import 'package:leet_block/models/leetcode_stats.dart';

import 'support/fakes.dart';
import 'support/platform_channel_mock.dart';
import 'support/provider_harness.dart';
import 'support/waiters.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('core setup to main navigation flow works', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final platformMock = PlatformChannelMock();
    await platformMock.install();
    addTearDown(() => platformMock.uninstall());

    final now = DateTime(2026, 2, 28, 10, 0);
    final fakeService =
        StubLeetCodeService(now: () => now)
          ..validateUsernameResult = (true, null)
          ..fetchUserStatsResult = LeetCodeStats(
            username: 'alice',
            totalSolved: 10,
            easySolved: 4,
            mediumSolved: 4,
            hardSolved: 2,
            recentSubmissions: 1,
            lastFetched: now,
            totalEasy: 100,
            totalMedium: 100,
            totalHard: 100,
          );

    final provider = await createIntegrationProvider(
      now: () => now,
      leetCodeService: fakeService,
      installedAppsGateway: FakeInstalledAppsGateway(
        apps: [
          fakeInstalledApp(packageName: 'com.example.app', name: 'Example App'),
        ],
      ),
      initialPrefs: const {},
    );

    await tester.pumpWidget(
      LeetBlockApp(provider: provider, autoStartBlockerService: false),
    );
    await waitForFinder(
      tester,
      find.byKey(const ValueKey('setup_username_input')),
      description: 'setup screen',
    );

    await tester.enterText(
      find.byKey(const ValueKey('setup_username_input')),
      'alice',
    );
    await tapWhenVisible(
      tester,
      find.byKey(const ValueKey('setup_validate_username_button')),
      description: 'validate username button',
    );
    await waitForFinder(
      tester,
      find.byKey(const ValueKey('setup_set_quota_button')),
      description: 'quota step',
    );

    await tapWhenVisible(
      tester,
      find.byKey(const ValueKey('setup_set_quota_button')),
      description: 'set quota button',
    );
    await waitForFinder(
      tester,
      find.byKey(const ValueKey('setup_request_notification_button')),
      description: 'notification step',
    );

    await tapWhenVisible(
      tester,
      find.byKey(const ValueKey('setup_skip_notification_button')),
      description: 'skip notification button',
    );
    await waitForFinder(
      tester,
      find.byKey(const ValueKey('setup_go_to_app_selection_button')),
      description: 'app selection navigation step',
    );

    await tapWhenVisible(
      tester,
      find.byKey(const ValueKey('setup_go_to_app_selection_button')),
      description: 'go to app selection button',
    );
    await waitForFinder(
      tester,
      find.byKey(const ValueKey('app_selection_done_button')),
      description: 'app selection screen',
    );

    await tapWhenVisible(
      tester,
      find.byKey(const ValueKey('app_selection_done_button')),
      description: 'done selecting apps',
    );
    await pumpUntil(
      tester,
      () => provider.isSetupComplete,
      description: 'setup completion after app selection',
    );
    expect(provider.isSetupComplete, isTrue);
    await waitForFinder(
      tester,
      find.byIcon(Icons.home_rounded),
      description: 'main home after setup',
    );

    await tapWhenVisible(
      tester,
      find.byIcon(Icons.list_alt_rounded),
      description: 'lists tab button',
    );

    await tapWhenVisible(
      tester,
      find.byIcon(Icons.bar_chart_rounded),
      description: 'statistics tab button',
    );

    await tapWhenVisible(
      tester,
      find.byIcon(Icons.home_rounded),
      description: 'home tab button',
    );
    await waitForFinder(
      tester,
      find.byKey(const ValueKey('home_refresh_progress_button')),
      description: 'home tab',
    );
    await tapWhenVisible(
      tester,
      find.byKey(const ValueKey('home_refresh_progress_button')),
      description: 'refresh progress button',
    );
  });
}
