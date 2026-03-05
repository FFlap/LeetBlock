import 'package:shared_preferences/shared_preferences.dart';

import 'package:leet_block/providers/leet_block_provider.dart';
import 'package:leet_block/services/installed_apps_gateway.dart';
import 'package:leet_block/services/leetcode_service.dart';
import 'package:leet_block/services/storage_service.dart';

Future<LeetBlockProvider> createIntegrationProvider({
  Map<String, Object> initialPrefs = const {},
  LeetCodeService? leetCodeService,
  InstalledAppsGateway? installedAppsGateway,
  DateTime Function()? now,
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs);
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs: prefs);
  await storageService.init();

  final provider = LeetBlockProvider(
    leetCodeService: leetCodeService,
    storageService: storageService,
    installedAppsGateway: installedAppsGateway,
    now: now,
  );

  await provider.init();
  return provider;
}
