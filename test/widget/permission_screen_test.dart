import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:leet_block/screens/permission_screen.dart';
import '../support/platform_channel_mock.dart';

void main() {
  testWidgets('PermissionScreen only notifies completion once', (tester) async {
    final channelMock = PlatformChannelMock(
      hasUsageStatsPermission: true,
      hasOverlayPermission: true,
    );
    await channelMock.install();

    var completionCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PermissionScreen(
          onAllPermissionsGranted: () {
            completionCalls++;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(completionCalls, 1);
    expect(channelMock.startServiceCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(completionCalls, 1);
    expect(channelMock.startServiceCalls, 1);
    await channelMock.uninstall();
  });

  testWidgets(
    'PermissionScreen shows error and skips completion when service start fails',
    (tester) async {
      final channelMock = PlatformChannelMock(
        hasUsageStatsPermission: true,
        hasOverlayPermission: true,
        startBlockerServiceResult: false,
      );
      await channelMock.install();

      var completionCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PermissionScreen(
            onAllPermissionsGranted: () {
              completionCalls++;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(completionCalls, 0);
      expect(channelMock.startServiceCalls, 1);
      expect(
        find.text('Failed to start blocker service. Please try again.'),
        findsOneWidget,
      );

      await channelMock.uninstall();
    },
  );

  testWidgets('PermissionScreen does not setState after dispose', (
    tester,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    const channel = MethodChannel('com.leetblock/app_blocker');
    final usagePermissionCompleter = Completer<bool>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'hasUsageStatsPermission') {
            return await usagePermissionCompleter.future;
          }
          if (call.method == 'hasOverlayPermission') {
            return false;
          }
          return null;
        });

    await tester.pumpWidget(
      MaterialApp(home: PermissionScreen(onAllPermissionsGranted: () {})),
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    usagePermissionCompleter.complete(false);
    await tester.pump();

    expect(tester.takeException(), isNull);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
