import 'dart:convert';
import 'dart:typed_data';

class BlockedAppInfo {
  final String packageName;
  final String appName;
  final Uint8List? icon;
  final bool isBlocked;

  BlockedAppInfo({
    required this.packageName,
    required this.appName,
    this.icon,
    this.isBlocked = false,
  });

  BlockedAppInfo copyWith({
    String? packageName,
    String? appName,
    Uint8List? icon,
    bool? isBlocked,
  }) {
    return BlockedAppInfo(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      icon: icon ?? this.icon,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isBlocked': isBlocked,
      'icon': icon != null ? base64Encode(icon!) : null,
    };
  }

  factory BlockedAppInfo.fromJson(Map<String, dynamic> json) {
    return BlockedAppInfo(
      packageName: json['packageName'] ?? '',
      appName: json['appName'] ?? '',
      isBlocked: json['isBlocked'] ?? false,
      icon: json['icon'] != null ? base64Decode(json['icon']) : null,
    );
  }
}

