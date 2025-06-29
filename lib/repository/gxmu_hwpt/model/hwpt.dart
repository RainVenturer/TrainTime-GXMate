// Copyright 2025 RainVenturer and contributors.
// SPDX-License-Identifier: MPL-2.0

// HWPT (后勤服务) class.

import 'package:json_annotation/json_annotation.dart';

part 'hwpt.g.dart';

@JsonSerializable(explicitToJson: true)
class Hwpt {
  // User info
  final String token;
  final String userId;
  final String mechanismId;
  final String sitesId;
  final String identityId;
  final String identityCode;
  final String studentNumber;
  final String cardNumber;
  // Index config
  final String campusId;
  final String account;
  final String password;
  final String deskey;

  Hwpt({
    required this.token,
    required this.userId,
    required this.mechanismId,
    required this.sitesId,
    required this.identityId,
    required this.identityCode,
    required this.studentNumber,
    required this.cardNumber,
    required this.campusId,
    required this.account,
    required this.password,
    required this.deskey,
  });

  factory Hwpt.empty() => Hwpt(
        token: "",
        userId: "",
        mechanismId: "",
        sitesId: "",
        identityId: "",
        identityCode: "",
        studentNumber: "",
        cardNumber: "",
        campusId: "",
        account: "",
        password: "",
        deskey: "",
      );

  // 将对象转换为JSON
  Map<String, dynamic> toJson() => _$HwptToJson(this);

  // 从JSON创建对象
  factory Hwpt.fromJson(Map<String, dynamic> json) => _$HwptFromJson(json);
}
