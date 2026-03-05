import 'package:flutter/services.dart';

class PlatformService {
  static const MethodChannel _channel = MethodChannel(
    'com.leetblock/app_blocker',
  );

  /// Check if app has usage stats permission
  static Future<bool> hasUsageStatsPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'hasUsageStatsPermission',
      );
      return result ?? false;
    } catch (e) {
      print('Error checking usage stats permission: $e');
      return false;
    }
  }

  /// Request usage stats permission (opens settings)
  static Future<void> requestUsageStatsPermission() async {
    try {
      await _channel.invokeMethod('requestUsageStatsPermission');
    } catch (e) {
      print('Error requesting usage stats permission: $e');
    }
  }

  /// Check if app has overlay permission
  static Future<bool> hasOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasOverlayPermission');
      return result ?? false;
    } catch (e) {
      print('Error checking overlay permission: $e');
      return false;
    }
  }

  /// Request overlay permission (opens settings)
  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (e) {
      print('Error requesting overlay permission: $e');
    }
  }

  /// Start the app blocker background service
  static Future<bool> startBlockerService() async {
    try {
      final result = await _channel.invokeMethod<bool>('startBlockerService');
      return result ?? false;
    } catch (e) {
      print('Error starting blocker service: $e');
      return false;
    }
  }

  /// Stop the app blocker background service
  static Future<void> stopBlockerService() async {
    try {
      await _channel.invokeMethod('stopBlockerService');
    } catch (e) {
      print('Error stopping blocker service: $e');
    }
  }

  /// Open LeetCode in browser
  static Future<void> openLeetCode() async {
    try {
      await _channel.invokeMethod('openLeetCode');
    } catch (e) {
      print('Error opening LeetCode: $e');
    }
  }

  /// Check if all required permissions are granted
  static Future<bool> hasAllPermissions() async {
    final hasUsageStats = await hasUsageStatsPermission();
    final hasOverlay = await hasOverlayPermission();
    return hasUsageStats && hasOverlay;
  }
}
