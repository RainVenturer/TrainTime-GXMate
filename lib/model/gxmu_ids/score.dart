// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

// ignore_for_file: non_constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'score.g.dart';

@JsonSerializable(explicitToJson: true)
class Score {
  int mark; // 编号，用于某种计算，从 0 开始
  String name; // 学科名称
  double? score; // 分数
  double? gradePoint; // 绩点
  String semesterCode; // 学年
  double credit; // 学分
  String classStatus; // 课程性质，必修，选修等，
  String classType; // 课程类别
  String scoreStatus; // 修读类型类型，正常考试、补考1、重修重考等
  String scoreType; // 等级成绩类型，百分制等（？）
  String? isPassedStr; //是否及格，null 没出分，1 通过 0 没有
  bool? isLevel; // 是否为等级成绩
  int? scoreCode; // 成绩代码
  String? level; // 等级
  bool? isMax; // 是否为最大成绩

  Score({
    required this.mark,
    required this.name,
    required this.score,
    required this.gradePoint,
    required this.semesterCode,
    required this.credit,
    required this.classStatus,
    required this.classType,
    required this.scoreStatus,
    required this.scoreType,
    required this.isPassedStr,
    this.isLevel,
    this.scoreCode,
    this.level,
    this.isMax,
  });

  bool? get isPassed {
    if (isPassedStr == null || isPassedStr == "null") return null;
    return isPassedStr == "1";
  }

  bool get isFinish => isPassed != null && score != null;

  String get scoreStr {
    if (score != null) {
      return score!.toInt().toString();
    } else if (isPassedStr == null) {
      return "暂无";
    } else if (isPassedStr!.contains('0')) {
      return "暂无但未及格";
    } else {
      return "暂无但及格";
    }
  }

  @override
  int get hashCode => name.hashCode ^ score.hashCode ^ isPassed.hashCode;

  @override
  bool operator ==(Object other) =>
      other is Score &&
      other.runtimeType == runtimeType &&
      name == other.name &&
      score == other.score &&
      isPassed == other.isPassed;

  double get gpa {
    return gradePoint ?? 0.00;
  }

  factory Score.fromJson(Map<String, dynamic> json) => _$ScoreFromJson(json);

  Map<String, dynamic> toJson() => _$ScoreToJson(this);
}

class ComposeDetail {
  String content;
  String ratio;
  String score;

  ComposeDetail({
    required this.content,
    required this.ratio,
    required this.score,
  });
}

class ComposeAnalyze {
  String type;
  String name;
  Map<String, int> scoreDsitribution;
  int total;
  int rank;

  ComposeAnalyze({
    required this.type,
    required this.name,
    required this.scoreDsitribution,
    required this.total,
    required this.rank,
  });
}
