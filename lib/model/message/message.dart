// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

@JsonSerializable(explicitToJson: true)
class UpdateMessage {
  final String code;
  final List<String> update;
  final String? ioslink;
  final String github;
  final String? fdroid;
  final String? apkUrl;

  UpdateMessage({
    required this.code,
    required this.update,
    this.ioslink,
    required this.github,
    this.fdroid,
    this.apkUrl,
  });

  factory UpdateMessage.fromJson(Map<String, dynamic> json) =>
      _$UpdateMessageFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateMessageToJson(this);

  factory UpdateMessage.fromGitHubRelease(Map<String, dynamic> releaseData) {
    final version = releaseData['tag_name'].toString().replaceAll('v', '');
    final notes = (releaseData['body'] ?? '').split('\n');
    final htmlUrl = releaseData['html_url'] as String;

    // Find APK asset if available
    final apkAsset = releaseData['assets']?.firstWhere(
      (asset) => asset['name'].toString().endsWith('.apk'),
      orElse: () => null,
    );
    final apkUrl = apkAsset?['browser_download_url'] as String?;

    return UpdateMessage(
      code: version,
      update: notes,
      github: htmlUrl,
      apkUrl: apkUrl,
    );
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
