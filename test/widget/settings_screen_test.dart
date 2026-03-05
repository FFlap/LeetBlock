import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:leet_block/models/leetcode_stats.dart';
import 'package:leet_block/providers/leet_block_provider.dart';
import 'package:leet_block/screens/settings_screen.dart';
import '../support/fakes.dart';
import '../support/platform_channel_mock.dart';
import '../support/provider_test_harness.dart';

Future<void> _pumpSettingsScreen(
  WidgetTester tester,
  LeetBlockProvider provider,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<LeetBlockProvider>.value(
      value: provider,
      child: MaterialApp(
        home: Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: const ValueKey('open_settings_button'),
                    onPressed:
                        () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                    child: const Text('Open Settings'),
                  ),
                ),
              ),
        ),
      ),
    ),
  );

  await tester.tap(find.byKey(const ValueKey('open_settings_button')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('SettingsScreen updates quota and manual progress controls', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final now = DateTime(2026, 2, 28, 10, 0);
    final provider = await createInitializedProvider(
      now: () => now,
      leetCodeService: StubLeetCodeService(now: () => now),
      initialPrefs: {
        'leetcode_username': 'alice',
        'daily_quota': 2,
        'daily_progress': jsonEncode(
          DailyProgress(
            date: now,
            questionsCompletedToday: 1,
            dailyQuota: 2,
            startOfDayTotal: 10,
            manualOffset: 0,
          ).toJson(),
        ),
        'last_stats': jsonEncode(
          LeetCodeStats(
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
          ).toJson(),
        ),
      },
    );

    await _pumpSettingsScreen(tester, provider);

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('settings_quota_slider')),
    );
    slider.onChanged?.call(5);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(provider.dailyQuota, 5);

    await _pumpSettingsScreen(tester, provider);

    await tester.tap(
      find.byKey(const ValueKey('settings_edit_todays_progress_button')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('settings_progress_increment_button')),
    );
    await tester.pumpAndSettle();
    expect(provider.manualOffset, 1);

    await tester.tap(
      find.byKey(const ValueKey('settings_progress_reset_offset_button')),
    );
    await tester.pumpAndSettle();
    expect(provider.manualOffset, 0);
  });

  testWidgets('SettingsScreen strict mode confirmation and reset work', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final platformMock = PlatformChannelMock();
    await platformMock.install();
    addTearDown(platformMock.uninstall);

    final now = DateTime(2026, 2, 28, 10, 0);
    final provider = await createInitializedProvider(
      now: () => now,
      leetCodeService: StubLeetCodeService(now: () => now),
      initialPrefs: {
        'leetcode_username': 'alice',
        'daily_progress': jsonEncode(
          DailyProgress(
            date: now,
            questionsCompletedToday: 1,
            dailyQuota: 2,
            startOfDayTotal: 10,
          ).toJson(),
        ),
      },
    );

    await _pumpSettingsScreen(tester, provider);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('settings_strict_mode_switch')),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.byKey(const ValueKey('settings_strict_mode_switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable'));
    await tester.pumpAndSettle();

    expect(provider.strictMode, isTrue);

    await tester.scrollUntilVisible(
      find.text('Reset App'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Reset App'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('settings_reset_confirmation_input')),
      'confirm',
    );
    await tester.tap(
      find.byKey(const ValueKey('settings_reset_everything_button')),
    );
    await tester.pumpAndSettle();

    expect(provider.username, isEmpty);
    expect(platformMock.stopServiceCalls, 1);
  });
}
