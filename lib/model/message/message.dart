// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

@JsonSerializable(explicitToJson: true)
class UpdateMessage {
  final String code;
  final List<String> update;
  final String? ioslink;
  final String github;
  final String? fdroid;
  final Map<String, String>? apkUrls;  // Map of architecture to download URL

  UpdateMessage({
    required this.code,
    required this.update,
    this.ioslink,
    required this.github,
    this.fdroid,
    this.apkUrls,
  });

  factory UpdateMessage.fromJson(Map<String, dynamic> json) =>
      _$UpdateMessageFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateMessageToJson(this);

  factory UpdateMessage.fromGitHubRelease(Map<String, dynamic> releaseData) {
    final version = releaseData['tag_name'].toString().replaceAll('v', '');
    final notes = (releaseData['body'] ?? '').split('\n');
    final htmlUrl = releaseData['html_url'] as String;
    
    // Parse APK assets
    final Map<String, String> apkUrls = {};
    final assets = releaseData['assets'] as List<dynamic>?;
    if (assets != null) {
      for (var asset in assets) {
        final name = asset['name'] as String;
        if (name.endsWith('.apk')) {
          // 解析文件名来确定架构
          String arch;
          if (name.contains('arm64-v8a')) {
            arch = 'arm64-v8a';
          } else if (name.contains('armeabi-v7a')) {
            arch = 'armeabi-v7a';
          } else if (name.contains('x86_64')) {
            arch = 'x86_64';
          } else {
            arch = 'universal';  // 默认通用版本
          }
          apkUrls[arch] = asset['browser_download_url'] as String;
        }
      }
    }

    return UpdateMessage(
      code: version,
      update: notes,
      github: htmlUrl,
      apkUrls: apkUrls.isNotEmpty ? apkUrls : null,
    );
  }

  String? getPreferredApkUrl() {
    if (apkUrls == null || apkUrls!.isEmpty) return null;

    // 获取设备 CPU 架构
    String arch = Platform.version.toLowerCase();
    
    // 按优先级尝试匹配合适的 APK
    if (arch.contains('arm64')) {
      return apkUrls!['arm64-v8a'] ?? 
             apkUrls!['armeabi-v7a'] ?? 
             apkUrls!['universal'];
    } else if (arch.contains('arm')) {
      return apkUrls!['armeabi-v7a'] ?? 
             apkUrls!['universal'];
    } else if (arch.contains('x86_64')) {
      return apkUrls!['x86_64'] ?? 
             apkUrls!['universal'];
    }
    
    // 如果没有找到匹配的，返回通用版本
    return apkUrls!['universal'] ?? apkUrls!.values.first;
  }
}

@JsonSerializable(explicitToJson: true)
class NoticeMessage {
  final String title;
  final String message;
  final String isLink;
  final String type;

  NoticeMessage({
    required this.title,
    required this.message,
    required this.isLink,
    required this.type,
  });

  factory NoticeMessage.fromJson(Map<String, dynamic> json) =>
      _$NoticeMessageFromJson(json);

  Map<String, dynamic> toJson() => _$NoticeMessageToJson(this);
}
