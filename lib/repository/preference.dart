// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

// General user setting preference.

import 'package:catcher_2/catcher_2.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:watermeter/repository/logger.dart';

late SharedPreferencesWithCache prefs;
late PackageInfo packageInfo;

final GlobalKey<NavigatorState> debuggerKey =
    GlobalKey<NavigatorState>(debugLabel: "PDADebuggerKey");
final GlobalKey<NavigatorState> splitViewKey =
    GlobalKey<NavigatorState>(debugLabel: "PDASplitKey");
final GlobalKey leftKey = GlobalKey();
const String appId = "group.xyz.superbart.xdyou";

Catcher2Options catcherOptions = Catcher2Options(
  PageReportMode(showStackTrace: true),
  [
    EmailManualHandler(
      ["maoyuuuuuu@qq.com"],
      emailTitle: "PDA 发生故障",
      emailHeader: "请作者尽快修复",
    ),
    ConsoleHandler(),
  ],
  localizationOptions: [
    LocalizationOptions.buildDefaultChineseOptions(),
  ],
  logger: PDACatcher2Logger(),
);

enum Preference {
  name(key: "name", type: "String"),
  // sex(key: "sex", type: "String"),
  // execution(key: "execution", type: "String"), // 书院
  institutes(key: "institutes", type: "String"), // 学院
  subject(key: "subject", type: "String"), // 专业
  dorm(key: "dorm", type: "String"), // 宿舍
  location(key: "location", type: "String"), // 宿舍位置
  idsAccount(key: "idsAccount", type: "String"), // 一站式帐号
  idsPassword(key: "idsPassword", type: "String"), // 一站式密码
  classString(key: "classString", type: "String"), // 班级
  isInHeadQuarters(key: "isInHeadquarters", type: "bool"), // 是否在本部
  idCardSix(key: "idCardSix", type: "String"), // 身份证后六位
  // sportPassword(key: "sportPassword", type: "String"), // 体育系统密码
  // experimentPassword(key: "experimentPassword", type: "String"), // 物理实验密码
  // electricityPassword(key: "electricityPassword", type: "String"), // 电费密码
  schoolCardPassword(key: "schoolCardPassword", type: "String"), // 校园卡密码
  decorated(key: "decorated", type: "bool"), // 课表是否开启背景
  decoration(key: "decoration", type: "bool"), // 背景图是否设置
  swift(key: "swift", type: "int"), // 周次偏移
  color(key: "color", type: "int"), // 颜色索引
  brightness(key: "brightness", type: "int"), // 深浅色模式
  currentSemester(key: "currentSemester", type: "String"), // 当前学期编码
  // currentStartDay(key: "currentStartDay", type: "String"), // 当前学期编码
  // role(key: "role", type: "bool"), // 是否为研究生
  simplifiedClassTimeline(
    key: "simplifiedClassTimeline",
    type: "bool",
  ), // 简化日程时间轴
  showEncourageWord(key: "showEncourageWord", type: "bool"), // 是否显示鼓励词
  localization(key: "localization", type: "String"); // 语言设置
  // schoolNetQueryPassword(
  //   key: "schoolNetQueryPassword",
  //   type: "String",
  // ), // 校园网查询密码
  // emptyClassroomLastChoice(
  //   key: "emptyClassroomLastChoice",
  //   type: "String",
  // ); // 空闲教室最后一次选择

  const Preference({required this.key, this.type = "String"});

  final String key;
  final String type;
}

String getString(Preference key) {
  if (key.type != 'String') {
    throw WrongTypeException;
  }
  return prefs.getString(key.key) ?? "";
}

bool getBool(Preference key) {
  if (key.type != 'bool') {
    throw WrongTypeException;
  }

  return prefs.getBool(key.key) ?? false;
}

int getInt(Preference key) {
  if (key.type != 'int') {
    throw WrongTypeException;
  }
  return prefs.getInt(key.key) ?? 0;
}

Future<void> setString(Preference key, String value) async {
  if (key.type != 'String') {
    throw WrongTypeException;
  }
  await prefs.setString(key.key, value);
  await prefs.reloadCache();
}

Future<void> setBool(Preference key, bool value) async {
  if (key.type != 'bool') {
    throw WrongTypeException;
  }
  await prefs.setBool(key.key, value);
  await prefs.reloadCache();
}

Future<void> setInt(Preference key, int value) async {
  if (key.type != 'int') {
    throw WrongTypeException;
  }
  await prefs.setInt(key.key, value);
  await prefs.reloadCache();
}

Future<void> remove(Preference key) async {
  await prefs.remove(key.key);
  await prefs.reloadCache();
}

Future<void> prefrenceClear() async {
  await prefs.clear();
  await prefs.reloadCache();
}

class NotRegisteredException implements Exception {}

class NotFoundException implements Exception {}

class WrongTypeException implements Exception {}
