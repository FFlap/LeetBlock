import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class PlatformChannelMock {
  static const MethodChannel _channel = MethodChannel(
    'com.leetblock/app_blocker',
  );

  bool hasUsageStatsPermission;
  bool hasOverlayPermission;
  bool? startBlockerServiceResult;
  int startServiceCalls = 0;
  int stopServiceCalls = 0;
  int openLeetCodeCalls = 0;

  PlatformChannelMock({
    this.hasUsageStatsPermission = true,
    this.hasOverlayPermission = true,
    this.startBlockerServiceResult,
  });

  Future<void> install() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          switch (call.method) {
            case 'hasUsageStatsPermission':
              return hasUsageStatsPermission;
            case 'hasOverlayPermission':
              return hasOverlayPermission;
            case 'requestUsageStatsPermission':
            case 'requestOverlayPermission':
              return null;
            case 'startBlockerService':
              startServiceCalls++;
              return startBlockerServiceResult ??
                  (hasUsageStatsPermission && hasOverlayPermission);
            case 'stopBlockerService':
              stopServiceCalls++;
              return null;
            case 'openLeetCode':
              openLeetCodeCalls++;
              return null;
            default:
              return null;
          }
        });
  }

  Future<void> uninstall() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }
}
