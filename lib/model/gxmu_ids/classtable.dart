// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0

// import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'classtable.g.dart';

enum Source {
  empty,
  school,
  user,
}

/* @JsonSerializable(explicitToJson: true)
class NotArrangementClassDetail {
  String name; // 名称
  String? code; // 课程序号
  String? number; // 班级序号
  String? teacher; // 老师

  NotArrangementClassDetail({
    required this.name,
    this.code,
    this.number,
    this.teacher,
  });

  factory NotArrangementClassDetail.from(NotArrangementClassDetail e) =>
      NotArrangementClassDetail(
        name: e.name,
        code: e.code,
        number: e.number,
        teacher: e.teacher,
      );

  factory NotArrangementClassDetail.fromJson(Map<String, dynamic> json) =>
      _$NotArrangementClassDetailFromJson(json);

  Map<String, dynamic> toJson() => _$NotArrangementClassDetailToJson(this);

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) =>
      other is ClassDetail &&
      other.runtimeType == runtimeType &&
      name == other.name;
}
 */
@JsonSerializable(explicitToJson: true)
class ClassDetail {
  String name; // 名称
  String? code; // 课程序号
  String? number; // 班级序号
  String? teacher; // 老师

  ClassDetail({
    required this.name,
    this.code,
    this.number,
    this.teacher,
  });

  factory ClassDetail.from(ClassDetail e) => ClassDetail(
        name: e.name,
        code: e.code,
        number: e.number,
        teacher: e.teacher,
      );

  factory ClassDetail.fromJson(Map<String, dynamic> json) =>
      _$ClassDetailFromJson(json);

  Map<String, dynamic> toJson() => _$ClassDetailToJson(this);

  @override
  int get hashCode => name.hashCode ^ teacher.hashCode;

  @override
  bool operator ==(Object other) =>
      other is ClassDetail &&
      other.runtimeType == runtimeType &&
      name == other.name &&
      teacher == other.teacher;

  @override
  String toString() {
    return "$name $code $number $teacher";
  }
}

@JsonSerializable(explicitToJson: true)
class TimeArrangement {
  /// 课程索引（注：是 `ClassDetail` 的索引，不是 `TimeArrangement` 的索引）
  int index;

  /// 返回的是布尔类型列表，true 表示该周有课，false 表示该周无课
  /// 绕过 Swift 字符串不好处理的代价就是 json 要大很多了......
  @JsonKey(name: 'week_list')
  List<bool> weekList;
  bool isWinter; // 是否为冬季时间
  String? teacher; // 老师
  int day; // 星期几上课
  int start; // 上课开始节次
  int stop; // 上课结束节次
  String startTime; // 上课开始时间
  String endTime; // 上课结束时间
  Source source; // 数据来源

  /// 不同周数对应的教室位置
  @JsonKey(includeIfNull: false)
  Map<String, String>? classroom;

  factory TimeArrangement.fromJson(Map<String, dynamic> json) =>
      _$TimeArrangementFromJson(json);

  Map<String, dynamic> toJson() => _$TimeArrangementToJson(this);

  TimeArrangement({
    required this.source,
    required this.isWinter,
    required this.index,
    required this.weekList,
    this.classroom,
    this.teacher,
    required this.day,
    required this.start,
    required this.stop,
    required this.startTime,
    required this.endTime,
  });

  @override
  String toString() => "$source $index $classroom $teacher";
}

@JsonSerializable(explicitToJson: true)
class ClassTableData {
  int semesterLength;
  String semesterCode;
  String termStartDay;
  List<ClassDetail> classDetail;
  List<ClassDetail> userDefinedDetail;
  List<TimeArrangement> timeArrangement;

  /// Only allowed to be used with classDetail
  ClassDetail getClassDetail(TimeArrangement t) {
    switch (t.source) {
      case Source.school:
        return classDetail[t.index];
      case Source.user:
        return userDefinedDetail[t.index];
      case Source.empty:
        throw NotImplementedException();
    }
  }

  ClassTableData.from(ClassTableData c)
      : this(
          semesterLength: c.semesterLength,
          semesterCode: c.semesterCode,
          termStartDay: c.termStartDay,
          classDetail: c.classDetail,
          timeArrangement: c.timeArrangement,
        );

  ClassTableData({
    this.semesterLength = 1,
    this.semesterCode = "",
    this.termStartDay = "",
    List<ClassDetail>? classDetail,
    List<ClassDetail>? userDefinedDetail,
    List<TimeArrangement>? timeArrangement,
  })  : classDetail = classDetail ?? [],
        userDefinedDetail = userDefinedDetail ?? [],
        timeArrangement = timeArrangement ?? [];

  factory ClassTableData.fromJson(Map<String, dynamic> json) =>
      _$ClassTableDataFromJson(json);

  Map<String, dynamic> toJson() => _$ClassTableDataToJson(this);
}

class NotImplementedException implements Exception {}
/* 
enum ChangeType {
  change, // 调课
  stop, // 停课
  patch, // 补课
} */

@JsonSerializable(explicitToJson: true)
/* class ClassChange {
  // final ChangeType type;

  /// kcdm 课程号
  final String classCode;

  /// dgksdm 班级号
  final String classNumber;

  /// kcmc 课程名
  final String className;

  /// 来自 SKZC 原周次信息，可能是空
  final List<bool>? originalAffectedWeeks;

  /// YSKJS 原先的老师
  final String? originalTeacherData;

  /// XSKJS 新换的老师
  final String? newTeacherData;

  /// KSJS-JSJC 原先的课次信息
  final List<int> originalClassRange;

  /// XKSJS-XJSJC 新的课次信息
  final List<int> newClassRange;

  /// SKXQ 原先的星期
  final int? originalWeek;

  /// XSKXQ 现在的星期
  final int? newWeek;

  /// JASMC 旧教室
  final String? originalClassroom;

  /// XJASMC 新教室
  final String? newClassroom;

  ClassChange({
    required this.type,
    required this.classCode,
    required this.classNumber,
    required this.className,
    required this.originalAffectedWeeks,
    required this.newAffectedWeeks,
    required this.originalTeacherData,
    required this.newTeacherData,
    required this.originalClassRange,
    required this.newClassRange,
    required this.originalWeek,
    required this.newWeek,
    required this.originalClassroom,
    required this.newClassroom,
  });

  /// 必须假设后台有问题，返回长度不一样的数组
  /// 亏他们想得出来用 01 表示布尔信息，日子不是这么省的啊
  List<int> get originalAffectedWeeksList {
    if (originalAffectedWeeks == null) return [];
    List<int> toReturn = [];
    for (int i = 0; i < originalAffectedWeeks!.length; ++i) {
      if (originalAffectedWeeks![i]) toReturn.add(i);
    }
    return toReturn;
  }

  List<int> get newAffectedWeeksList {
    List<int> toReturn = [];
    for (int i = 0; i < (newAffectedWeeks?.length ?? 0); ++i) {
      if (newAffectedWeeks![i]) toReturn.add(i);
    }
    return toReturn;
  }

  String? get originalTeacher =>
      originalTeacherData?.replaceAll(RegExp(r'(/|[0-9a-zA-z])'), '');

  String? get newTeacher =>
      newTeacherData?.replaceAll(RegExp(r'(/|[0-9a-zA-z])'), '');

  String? get originalNewTeacher => newTeacherData;

  bool get isTeacherChanged {
    List<String> originalTeacherCode =
        originalTeacherData?.replaceAll(' ', '').split(RegExp(r',|/')) ?? [];

    originalTeacherCode
        .retainWhere((element) => element.contains(RegExp(r'([0-9])')));

    List<String> newTeacherCode =
        newTeacherData?.replaceAll(' ', '').split(RegExp(r',|/')) ?? [];

    newTeacherCode
        .retainWhere((element) => element.contains(RegExp(r'([0-9])')));

    return !listEquals(originalTeacherCode, newTeacherCode);
  }

  String get changeTypeString {
    switch (type) {
      case ChangeType.change:
        return "调课";
      case ChangeType.patch:
        return "补课";
      case ChangeType.stop:
        return "停课";
    }
  }

  factory ClassChange.fromJson(Map<String, dynamic> json) =>
      _$ClassChangeFromJson(json);

  Map<String, dynamic> toJson() => _$ClassChangeToJson(this);
}
 */
@JsonSerializable(explicitToJson: true)
class UserDefinedClassData {
  List<ClassDetail> userDefinedDetail;
  List<TimeArrangement> timeArrangement;

  UserDefinedClassData({
    required this.userDefinedDetail,
    required this.timeArrangement,
  });

  factory UserDefinedClassData.fromJson(Map<String, dynamic> json) =>
      _$UserDefinedClassDataFromJson(json);

  factory UserDefinedClassData.empty() =>
      UserDefinedClassData(userDefinedDetail: [], timeArrangement: []);

  Map<String, dynamic> toJson() => _$UserDefinedClassDataToJson(this);
}

// Time arrangements.
// Even means start, odd means end.
List<String> winterTime = [
  // 冬季时间
  "08:00",
  "08:40", // 第一节
  "08:50",
  "09:30", // 第二节
  "09:40",
  "10:20", // 第三节
  "10:30",
  "11:10", // 第四节
  "11:20",
  "12:00", // 第五节
  "14:30",
  "15:10", // 第六节
  "15:20",
  "16:00", // 第七节
  "16:10",
  "16:50", // 第八节
  "17:00",
  "17:40", // 第九节
  "19:30",
  "20:10", // 第十节
  "20:20",
  "21:00", // 第十一节
  "21:10",
  "21:50", // 第十二节
];

List<String> summerTime = [
  // 夏季时间
  "08:00",
  "08:40", // 第一节
  "08:50",
  "09:30", // 第二节
  "09:40",
  "10:20", // 第三节
  "10:30",
  "11:10", // 第四节
  "11:20",
  "12:00", // 第五节
  "15:00",
  "15:40", // 第六节
  "15:50",
  "16:30", // 第七节
  "16:40",
  "17:20", // 第八节
  "17:30",
  "18:10", // 第九节
  "19:30",
  "20:10", // 第十节
  "20:20",
  "21:00", // 第十一节
  "21:10",
  "21:50", // 第十二节
];
