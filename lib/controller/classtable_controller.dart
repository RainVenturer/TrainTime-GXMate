// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:watermeter/bridge/save_to_groupid.g.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:get/get.dart';
import 'package:watermeter/model/home_arrangement.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/model/gxmu_ids/classtable.dart';
import 'package:watermeter/repository/gxmu_ids/classtable_session.dart';

enum ClassTableState {
  fetching,
  fetched,
  error,
  none,
}

class ClassTableController extends GetxController {
  // Classtable state
  String? error;
  ClassTableState state = ClassTableState.none;

  // Classtable Data
  late File classTableFile;
  late File userDefinedFile;
  late ClassTableData classTableData;
  late UserDefinedClassData userDefinedClassData;

  // Get ClassDetail name info
  ClassDetail getClassDetail(TimeArrangement timeArrangementIndex) =>
      classTableData.getClassDetail(timeArrangementIndex);

  bool isTomorrow(DateTime updateTime) =>
      updateTime.hour * 60 + updateTime.minute > 21 * 60 + 25;

  int getCurrentWeek(DateTime now) {
    // Get the current index.
    int delta = now.difference(startDay).inDays;
    if (delta < 0) delta = -7;
    return delta ~/ 7;
  }

  /// Get all of [updateTime]'s arrangement in classtable
  List<HomeArrangement> getArrangementOfDay(DateTime updateTime) {
    DateFormat formatter = DateFormat(HomeArrangement.format);
    int currentWeek = getCurrentWeek(updateTime);
    Set<HomeArrangement> getArrangement = {};
    if (currentWeek >= 0 && currentWeek < classTableData.semesterLength) {
      for (var i in classTableData.timeArrangement) {
        if (i.weekList.length > currentWeek &&
            i.weekList[currentWeek] &&
            i.day == updateTime.weekday) {
          getArrangement.add(HomeArrangement(
            name: getClassDetail(i).name,
            teacher: i.teacher,
            place: i.classroom?[(currentWeek + 1).toString()],
            startTimeStr: formatter.format(DateTime(
              updateTime.year,
              updateTime.month,
              updateTime.day,
              i.isWinter
                  ? int.parse(winterTime[(i.start - 1) * 2].split(':')[0])
                  : int.parse(summerTime[(i.start - 1) * 2].split(':')[0]),
              i.isWinter
                  ? int.parse(winterTime[(i.start - 1) * 2].split(':')[1])
                  : int.parse(summerTime[(i.start - 1) * 2].split(':')[1]),
            )),
            endTimeStr: formatter.format(DateTime(
              updateTime.year,
              updateTime.month,
              updateTime.day,
              i.isWinter
                  ? int.parse(winterTime[(i.stop - 1) * 2 + 1].split(':')[0])
                  : int.parse(summerTime[(i.stop - 1) * 2 + 1].split(':')[0]),
              i.isWinter
                  ? int.parse(winterTime[(i.stop - 1) * 2 + 1].split(':')[1])
                  : int.parse(summerTime[(i.stop - 1) * 2 + 1].split(':')[1]),
            )),
          ));
        }
      }
    }

    return getArrangement.toList();
  }

  @override
  void onInit() {
    super.onInit();
    log.info(
      "[ClassTableController][onInit] "
      "Init classtable file.",
    );
    classTableFile = File(
      "${supportPath.path}/${ClassTableFile.schoolClassName}",
    );
    bool classTableFileisExist = classTableFile.existsSync();
    if (classTableFileisExist) {
      log.info(
        "[ClassTableController][onInit] "
        "Init from cache.",
      );
      classTableData = ClassTableData.fromJson(jsonDecode(
        classTableFile.readAsStringSync(),
      ));
      state = ClassTableState.fetched;
    } else {
      log.info(
        "[ClassTableController][onInit] "
        "Init from empty.",
      );
      classTableData = ClassTableData();
    }

    log.info(
      "[ClassTableController][onInit] "
      "Init user defined file.",
    );
    refreshUserDefinedClass();
  }

  @override
  void onReady() async {
    await updateClassTable();
  }

  void refreshUserDefinedClass() {
    userDefinedFile = File(
      "${supportPath.path}/${ClassTableFile.userDefinedClassName}",
    );
    bool userDefinedFileIsExist = userDefinedFile.existsSync();
    if (!userDefinedFileIsExist) {
      userDefinedFile.writeAsStringSync(
        jsonEncode(UserDefinedClassData.empty()),
      );
    }
    userDefinedClassData = UserDefinedClassData.fromJson(
      jsonDecode(userDefinedFile.readAsStringSync()),
    );
  }

  Future<void> addUserDefinedClass(
    ClassDetail classDetail,
    TimeArrangement timeArrangement,
  ) async {
    userDefinedClassData.userDefinedDetail.add(classDetail);
    timeArrangement.index = userDefinedClassData.userDefinedDetail.length - 1;
    userDefinedClassData.timeArrangement.add(timeArrangement);
    userDefinedFile.writeAsStringSync(jsonEncode(
      userDefinedClassData.toJson(),
    ));
    await updateClassTable(isUserDefinedChanged: true);
  }

  Future<void> editUserDefinedClass(
    TimeArrangement oldTimeArrangment,
    ClassDetail classDetail,
    TimeArrangement timeArrangement,
  ) async {
    if (oldTimeArrangment.source != Source.user) return;
    int tempIndex = oldTimeArrangment.index;
    userDefinedClassData.timeArrangement.remove(oldTimeArrangment);
    userDefinedClassData.userDefinedDetail[tempIndex] = classDetail;
    timeArrangement.index = tempIndex;
    userDefinedClassData.timeArrangement.add(timeArrangement);
    userDefinedFile.writeAsStringSync(jsonEncode(
      userDefinedClassData.toJson(),
    ));
    await updateClassTable(isUserDefinedChanged: true);
  }

  Future<void> deleteUserDefinedClass(
    TimeArrangement timeArrangement,
  ) async {
    if (timeArrangement.source != Source.user) return;
    int tempIndex = timeArrangement.index;
    userDefinedClassData.timeArrangement.remove(timeArrangement);
    userDefinedClassData.userDefinedDetail.removeAt(timeArrangement.index);
    for (var i in userDefinedClassData.timeArrangement) {
      if (i.index >= tempIndex) i.index -= 1;
    }
    userDefinedFile.writeAsStringSync(jsonEncode(
      userDefinedClassData.toJson(),
    ));
    await updateClassTable(isUserDefinedChanged: true);
  }

  /// The start day of the semester.
  DateTime get startDay => DateTime.parse(classTableData.termStartDay)
      .add(Duration(days: 7 * preference.getInt(preference.Preference.swift)));

  Future<void> updateClassTable({
    bool isForce = false,
    bool isUserDefinedChanged = false,
  }) async {
    state = ClassTableState.fetching;
    error = null;
    try {
      log.info(
        "[ClassTableController][updateClassTable] "
        "Start fetching the classtable.",
      );

      refreshUserDefinedClass();
      bool classTableFileIsExist = classTableFile.existsSync();
      bool isNotNeedRefreshCache = classTableFileIsExist &&
          !isForce &&
          DateTime.now().difference(classTableFile.lastModifiedSync()).inDays <=
              2;

      log.info(
        "[ClassTableController][updateClassTable]"
        "Cache file exist: $classTableFileIsExist.\n"
        "Is not need refresh cache: $isNotNeedRefreshCache\n"
        "Is user class changed: $isUserDefinedChanged",
      );

      if (isNotNeedRefreshCache || isUserDefinedChanged) {
        classTableData = ClassTableData.fromJson(jsonDecode(
          classTableFile.readAsStringSync(),
        ));
        classTableData.userDefinedDetail =
            userDefinedClassData.userDefinedDetail;
        classTableData.timeArrangement
            .addAll(userDefinedClassData.timeArrangement);
      } else {
        try {
          // bool isPostGraduate = preference.getBool(preference.Preference.role);
          // var toUse = isPostGraduate
          //     ? await ClassTableFile().getYjspt()
          //     : await ClassTableFile().getEhall();
          var toUse = await ClassTableFile().getEhall();
          classTableFile.writeAsStringSync(jsonEncode(toUse.toJson()));
          toUse.userDefinedDetail = userDefinedClassData.userDefinedDetail;
          toUse.timeArrangement.addAll(userDefinedClassData.timeArrangement);
          classTableData = toUse;
        } catch (e, s) {
          log.handle(e, s);
          if (classTableFileIsExist) {
            classTableData = ClassTableData.fromJson(jsonDecode(
              classTableFile.readAsStringSync(),
            ));
            classTableData.userDefinedDetail =
                userDefinedClassData.userDefinedDetail;
            classTableData.timeArrangement
                .addAll(userDefinedClassData.timeArrangement);
          } else {
            rethrow;
          }
        }
      }

      /// If ios, store the file to groupid public place
      /// in order to refresh the widget...
      if (Platform.isIOS) {
        final api = SaveToGroupIdSwiftApi();
        try {
          bool data = await api.saveToGroupId(FileToGroupID(
            appid: preference.appId,
            fileName: "ClassTable.json",
            data: jsonEncode(classTableData.toJson()),
          ));
          log.info(
            "[ClassTableController][updateClassTable] "
            "ios ClassTable.json save to public place status: $data.",
          );
        } catch (e, s) {
          log.handle(e, s);
        }
        try {
          bool data = await api.saveToGroupId(FileToGroupID(
            appid: preference.appId,
            fileName: "WeekSwift.txt",
            data: preference.getInt(preference.Preference.swift).toString(),
          ));
          log.info(
            "[ClassTableController][updateClassTable] "
            "ios WeekSwift.txt save to public place status: $data.",
          );
        } catch (e, s) {
          log.handle(e, s);
        }
        HomeWidget.updateWidget(
          iOSName: "ClasstableWidget",
          qualifiedAndroidName: "io.github.rainventurer.traintime_GXMate."
              "widget.classtable.ClassTableWidgetProvider",
        );
      }

      state = ClassTableState.fetched;
      error = null;
      update();
    } catch (e, s) {
      log.warning(e, s);
      state = ClassTableState.error;
      error = e.toString();
    }
  }
}
