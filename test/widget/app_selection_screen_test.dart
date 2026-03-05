import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:leet_block/providers/leet_block_provider.dart';
import 'package:leet_block/screens/app_selection_screen.dart';

import '../support/fakes.dart';
import '../support/provider_test_harness.dart';

void main() {
  testWidgets('AppSelectionScreen filters system apps and toggles blocking', (
    tester,
  ) async {
    final provider = await createInitializedProvider(
      leetCodeService: StubLeetCodeService(),
      installedAppsGateway: FakeInstalledAppsGateway(
        apps: [
          fakeInstalledApp(
            packageName: 'com.example.focusapp',
            name: 'Focus App',
          ),
          fakeInstalledApp(
            packageName: 'com.google.android.youtube',
            name: 'YouTube',
          ),
          fakeInstalledApp(
            packageName: 'com.android.systemui',
            name: 'System UI',
          ),
          fakeInstalledApp(
            packageName: 'com.leetblock.leet_block',
            name: 'LeetBlock',
          ),
        ],
      ),
      initialPrefs: const {},
    );
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<LeetBlockProvider>.value(
        value: provider,
        child: const MaterialApp(home: AppSelectionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Focus App'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.text('System UI'), findsNothing);
    expect(find.text('LeetBlock'), findsNothing);

    await tester.tap(find.text('Focus App'));
    await tester.pumpAndSettle();
    expect(provider.isAppBlocked('com.example.focusapp'), isTrue);
    expect(find.textContaining('1 app selected'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('app_selection_search_input')),
      'you',
    );
    await tester.pumpAndSettle();

    expect(find.text('YouTube'), findsOneWidget);
    expect(find.text('Focus App'), findsNothing);
  });
}
