import 'dart:typed_data';

import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class InstalledAppEntry {
  final String packageName;
  final String name;
  final Uint8List? icon;

  const InstalledAppEntry({
    required this.packageName,
    required this.name,
    required this.icon,
  });
}

abstract class InstalledAppsGateway {
  Future<List<InstalledAppEntry>> getInstalledApps({
    required bool includeSystemApps,
    required bool withIcons,
  });
}

class DefaultInstalledAppsGateway implements InstalledAppsGateway {
  const DefaultInstalledAppsGateway();

  @override
  Future<List<InstalledAppEntry>> getInstalledApps({
    required bool includeSystemApps,
    required bool withIcons,
  }) async {
    final apps = await InstalledApps.getInstalledApps(
      includeSystemApps,
      withIcons,
    );

    return apps
        .map(
          (AppInfo app) => InstalledAppEntry(
            packageName: app.packageName,
            name: app.name,
            icon: app.icon,
          ),
        )
        .toList();
  }
}
