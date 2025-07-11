// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:json_annotation/json_annotation.dart';

part 'electricity.g.dart';

@JsonSerializable()
class ElectricityInfo {
  DateTime fetchDay;
  String location;
  String remain;

  ElectricityInfo({
    required this.fetchDay,
    required this.remain,
    required this.location,
  });

  factory ElectricityInfo.empty(
    DateTime time,
  ) =>
      ElectricityInfo(
        fetchDay: time,
        remain: "electricity_status.pending",
        location: "electricity_status.pending",
      );

  factory ElectricityInfo.fromJson(Map<String, dynamic> json) =>
      _$ElectricityInfoFromJson(json);

  Map<String, dynamic> toJson() => _$ElectricityInfoToJson(this);
}
