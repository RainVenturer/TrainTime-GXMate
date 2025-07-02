// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

// The class table window source.

import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:jiffy/jiffy.dart';
// import 'package:watermeter/page/login/jc_captcha.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/model/gxmu_ids/classtable.dart';
import 'package:watermeter/repository/gxmu_ids/jwxt_session.dart';

/// 教务系统 197e093f7ffa4700b498da0ce3c88269
class ClassTableFile extends JwxtSession {
  static const schoolClassName = "ClassTable.json";
  static const userDefinedClassName = "UserClass.json";
  static const partnerClassName = "darling.erc.json";
  static const decorationName = "decoration.jpg";

  int getDiffMinutes(String time1, String time2) {
    DateTime t1 = DateTime.parse("2025-01-01 $time1:00");
    DateTime target = DateTime.parse("2025-01-01 $time2:00");
    return t1.difference(target).inMinutes.abs();
  }

  List<int> getResultJcdm(String startTime, String endTime, bool isWinter) {
    int start = 0;
    int end = 0;
    if (isWinter) {
      if (winterTime.contains(startTime.substring(0, 5))) {
        start = winterTime.indexOf(startTime.substring(0, 5)) ~/ 2 + 1;
      } else {
        // Find closest standard class time
        int minDiff = 24 * 60; // 24 hours * 60 minutes
        for (int i = 0; i < winterTime.length; i += 2) {
          int diff = getDiffMinutes(startTime.substring(0, 5), winterTime[i]);
          if (diff < minDiff) {
            minDiff = diff;
            start = (i ~/ 2) + 1;
          }
        }
      }
      if (winterTime.contains(endTime.substring(0, 5))) {
        end = winterTime.indexOf(endTime.substring(0, 5)) ~/ 2 + 1;
      } else {
        // Find closest standard class time
        int minDiff = 24 * 60; // 24 hours * 60 minutes
        for (int i = 0; i < winterTime.length; i += 2) {
          int diff = getDiffMinutes(endTime.substring(0, 5), winterTime[i]);
          if (diff < minDiff) {
            minDiff = diff;
            end = (i ~/ 2) + 1;
          }
        }
      }
    } else {
      if (summerTime.contains(startTime.substring(0, 5))) {
        start = summerTime.indexOf(startTime.substring(0, 5)) ~/ 2 + 1;
      } else {
        // Find closest standard class time
        int minDiff = 24 * 60; // 24 hours * 60 minutes
        for (int i = 0; i < summerTime.length; i += 2) {
          int diff = getDiffMinutes(startTime.substring(0, 5), summerTime[i]);
          if (diff < minDiff) {
            minDiff = diff;
            start = (i ~/ 2) + 1;
          }
        }
      }
      if (summerTime.contains(endTime.substring(0, 5))) {
        end = summerTime.indexOf(endTime.substring(0, 5)) ~/ 2 + 1;
      } else {
        // Find closest standard class time
        int minDiff = 24 * 60; // 24 hours * 60 minutes
        for (int i = 0; i < summerTime.length; i += 2) {
          int diff = getDiffMinutes(endTime.substring(0, 5), summerTime[i]);
          if (diff < minDiff) {
            minDiff = diff;
            end = (i ~/ 2) + 1;
          }
        }
      }
    }
    return [start, end];
  }

  ClassTableData simplifyData(Map<String, dynamic> qResult) {
    ClassTableData toReturn = ClassTableData();

    toReturn.semesterCode = qResult["semesterCode"];
    toReturn.termStartDay = qResult["termStartDay"];

    log.info(
      "[getClasstable][simplifyData] "
      "${toReturn.semesterCode} ${toReturn.termStartDay}",
    );

    for (var i in qResult["data"]) {
      var toDeal = ClassDetail(
        name: i["kcmc"],
        code: i["kcdm"],
        number: i["jxbmc"],
        teacher: i["teaxms"],
      );
      if (!toReturn.classDetail.contains(toDeal)) {
        toReturn.classDetail.add(toDeal);
      }

      List<int> classWeek = [];
      Map<String, String> classroomList = {}; // 教室列表，星期-教室
      if (i["jxcdmc2"] == null || i["jxcdmc2"].toString().isEmpty) {
        log.warning(
          "[getClasstable][simplifyData] "
          "Class ${toDeal.name} has no classroom list.",
        );
      }
      List<String> classroomclassWeek = i["jxcdmc2"].toString().split(",");
      for (var j in classroomclassWeek) {
        // 找到最后一个 '-' 的位置
        int lastDashIndex = j.lastIndexOf('-');
        if (lastDashIndex == -1) {
            log.warning(
                "[getClasstable][simplifyData] "
                "Invalid classroom format: $j",
            );
            continue;
        }
        
        // 分割地点和周数
        String location = j.substring(0, lastDashIndex);
        String weekStr = j.substring(lastDashIndex + 1);
        
        try {
            int week = int.parse(weekStr);
            classroomList[week.toString()] = location;
            classWeek.add(week);
        } catch (e) {
            log.warning(
                "[getClasstable][simplifyData] "
                "Failed to parse week number from: $j, Error: $e",
            );
        }
      }
      int maxWeek = classWeek.reduce((a, b) => a > b ? a : b);
      List<bool> weekList = List<bool>.generate(
        maxWeek,
        (index) => classWeek.contains(index + 1),
      );
      if (weekList.isEmpty) {
        log.warning(
          "[getClasstable][simplifyData] "
          "Class ${toDeal.name} has no week list.",
        );
      }
      // if (i["xnxqdm"][5] == "1") {
      //   start = winterTime.indexOf(i["qssj"].substring(0, 5)) ~/ 2 + 1;
      //   stop = winterTime.indexOf(i["jssj"].substring(0, 5)) ~/ 2 + 1;
      // } else {
      //   start = summerTime.indexOf(i["qssj"].substring(0, 5)) ~/ 2 + 1;
      //   stop = summerTime.indexOf(i["jssj"].substring(0, 5)) ~/ 2 + 1;
      // }
      List<int> resultTime =
          getResultJcdm(i["qssj"], i["jssj"], i["xnxqdm"][5] == "1");

      toReturn.timeArrangement.add(
        TimeArrangement(
          source: Source.school,
          isWinter: i["xnxqdm"][5] == "1" ? true : false,
          index: toReturn.classDetail.indexOf(toDeal),
          startTime: i["qssj"].toString().substring(0, 5), // 上课开始时间
          endTime: i["jssj"].toString().substring(0, 5), // 上课结束时间
          start: resultTime[0], // 上课开始节次
          teacher: i["teaxms"], // 任课教师
          stop: resultTime[1], // 上课结束节次
          day: i["xq"], // 上课星期
          weekList: weekList, // 上课周次
          classroom: classroomList,
        ),
      );
      if (weekList.length > toReturn.semesterLength) {
        toReturn.semesterLength = weekList.length;
      }
    }
    /*
    // Deal with the not arranged data.
    for (var i in qResult["notArranged"]) {
      toReturn.notArranged.add(NotArrangementClassDetail(
        name: i["KCM"],
        code: i["KCH"],
        number: i["KXH"],
        teacher: i["SKJS"],
      ));
    }*/

    return toReturn;
  }

  // Future<ClassTableData> getYjspt() async {
  //   Map<String, dynamic> qResult = {};

  //   const semesterCodeURL =
  //       "https://yjspt.xidian.edu.cn/gsapp/sys/wdkbapp/modules/xskcb/kfdxnxqcx.do";
  //   const classInfoURL =
  //       "https://yjspt.xidian.edu.cn/gsapp/sys/wdkbapp/modules/xskcb/xspkjgcx.do";
  //   const notArrangedInfoURL =
  //       "https://yjspt.xidian.edu.cn/gsapp/sys/wdkbapp/modules/xskcb/xswsckbkc.do";

  //   log.info("[getClasstable][getYjspt] Login the system.");
  //   String? location = await checkAndLogin(
  //     target: "https://yjspt.xidian.edu.cn/gsapp/"
  //         "sys/wdkbapp/*default/index.do#/xskcb",
  //     sliderCaptcha: (String cookieStr) =>
  //         SliderCaptchaClientProvider(cookie: cookieStr).solve(null),
  //   );

  //   while (location != null) {
  //     var response = await dio.get(location);
  //     log.info("[getClasstable][getYjspt] Received location: $location.");
  //     location = response.headers[HttpHeaders.locationHeader]?[0];
  //   }

  //   /// AKA xnxqdm as [startyear][period] eg 20242 as
  //   var semesterCode = await dio
  //       .post(semesterCodeURL)
  //       .then((value) => value.data["datas"]["kfdxnxqcx"]["rows"][0]["WID"]);

  //   DateTime now = DateTime.now();
  //   var currentWeek = await dio.post(
  //     'https://yjspt.xidian.edu.cn/gsapp/sys/yjsemaphome/portal/queryRcap.do',
  //     data: {'day': Jiffy.parseFromDateTime(now).format(pattern: "yyyyMMdd")},
  //   ).then((value) => value.data);
  //   if (!currentWeek.toString().contains("xnxq")) {
  //     return ClassTableData(
  //       semesterCode: semesterCode,
  //       termStartDay: "2025-01-01",
  //     );
  //   }
  //   currentWeek =
  //       RegExp(r'[0-9]+').firstMatch(currentWeek["xnxq"])?[0] ?? "null";

  //   log.info(
  //     "[getClasstable][getYjspt] Current week is $currentWeek, fetching...",
  //   );
  //   int weekDay = now.weekday - 1;
  //   String termStartDay = Jiffy.parseFromDateTime(now)
  //       .add(weeks: 1 - int.parse(currentWeek), days: -weekDay)
  //       .startOf(Unit.day)
  //       .format(pattern: "yyyy-MM-dd HH:mm:ss");

  //   if (preference.getString(preference.Preference.currentSemester) !=
  //       semesterCode) {
  //     preference.setString(
  //       preference.Preference.currentSemester,
  //       semesterCode,
  //     );

  //     /// New semenster, user defined class is useless.
  //     var userClassFile = File("${supportPath.path}/$userDefinedClassName");
  //     if (userClassFile.existsSync()) userClassFile.deleteSync();
  //   }

  //   Map<String, dynamic> data = await dio.post(classInfoURL, data: {
  //     "XNXQDM": semesterCode,
  //   }).then((response) => response.data);

  //   if (data['code'] != "0") {
  //     log.warning(
  //       "[getClasstable][getYjspt] "
  //       "extParams: ${data['extParams']['msg']} isNotPublish: "
  //       "${data['extParams']['msg'].toString().contains("查询学年学期的课程未发布")}",
  //     );
  //     if (data['extParams']['msg'].toString().contains("查询学年学期的课程未发布")) {
  //       log.warning(
  //         "[getClasstable][getYjspt] "
  //         "extParams: ${data['extParams']['msg']} isNotPublish: "
  //         "Classtable not released.",
  //       );
  //       return ClassTableData(
  //         semesterCode: semesterCode,
  //         termStartDay: termStartDay,
  //       );
  //     } else {
  //       throw Exception("${data['extParams']['msg']}");
  //     }
  //   }

  //   qResult["rows"] = data["datas"]["xspkjgcx"]["rows"];

  //   var notOnTable = await dio.post(
  //     notArrangedInfoURL,
  //     data: {
  //       'XNXQDM': semesterCode,
  //       'XH': preference.getString(preference.Preference.idsAccount),
  //     },
  //   ).then((value) => value.data['datas']['xswsckbkc']);
  //   qResult["notArranged"] = notOnTable["rows"];

  //   ClassTableData toReturn = ClassTableData();
  //   toReturn.semesterCode = semesterCode;
  //   toReturn.termStartDay = termStartDay;

  //   log.info(
  //     "[getClasstable][getYjspt] "
  //     "${toReturn.semesterCode} ${toReturn.termStartDay}",
  //   );

  //   for (var i in qResult["rows"]) {
  //     var toDeal = ClassDetail(
  //       name: i["KCMC"],
  //       code: i["KCDM"],
  //     );
  //     if (!toReturn.classDetail.contains(toDeal)) {
  //       toReturn.classDetail.add(toDeal);
  //     }

  //     toReturn.timeArrangement.add(
  //       TimeArrangement(
  //         source: Source.school,
  //         index: toReturn.classDetail.indexOf(toDeal),
  //         start: i["KSJCDM"],
  //         teacher: i["JSXM"],
  //         stop: i["JSJCDM"],
  //         day: int.parse(i["XQ"].toString()),
  //         weekList: List<bool>.generate(
  //           i["ZCBH"].toString().length,
  //           (index) => i["ZCBH"].toString()[index] == "1",
  //         ),
  //         classroom: i["JASMC"],
  //       ),
  //     );

  //     if (i["ZCBH"].toString().length > toReturn.semesterLength) {
  //       toReturn.semesterLength = i["ZCBH"].toString().length;
  //     }
  //   }

  //   // Post deal here
  //   List<TimeArrangement> newStuff = [];
  //   int getCourseId(TimeArrangement i) =>
  //       "${i.weekList}-${i.day}-${i.classroom}".hashCode;

  //   for (var i = 0; i < toReturn.classDetail.length; ++i) {
  //     List<TimeArrangement> data =
  //         List<TimeArrangement>.from(toReturn.timeArrangement)
  //           ..removeWhere((item) => item.index != i);
  //     List<int> entries = [];
  //     //Map<int, List<TimeArrangement>> toAdd = {};

  //     for (var j in data) {
  //       int id = getCourseId(j);
  //       if (!entries.any((k) => k == id)) entries.add(id);
  //     }
  //     for (var j in entries) {
  //       List<TimeArrangement> result = List<TimeArrangement>.from(data)
  //         ..removeWhere((item) => getCourseId(item) != j)
  //         ..sort((a, b) => a.start - b.start);

  //       List<int> arrangementsProto = {
  //         for (var i in result) ...[i.start, i.stop]
  //       }.toList()
  //         ..sort();

  //       log.info(arrangementsProto);

  //       List<List<int>> arrangements = [[]];
  //       for (var j in arrangementsProto) {
  //         if (arrangements.last.isEmpty || arrangements.last.last == j - 1) {
  //           arrangements.last.add(j);
  //         } else {
  //           arrangements.add([j]);
  //         }
  //       }

  //       log.info(arrangements);

  //       for (var j in arrangements) {
  //         newStuff.add(TimeArrangement(
  //           source: Source.school,
  //           index: i,
  //           classroom: result.first.classroom,
  //           teacher: result.first.teacher,
  //           weekList: result.first.weekList,
  //           day: result.first.day,
  //           start: j.first,
  //           stop: j.last,
  //         ));
  //       }
  //     }
  //   }

  //   toReturn.timeArrangement = newStuff;

  //   for (var i in qResult["notArranged"]) {
  //     toReturn.notArranged.add(NotArrangementClassDetail(
  //       name: i["KCMC"],
  //       code: i["KCDM"],
  //     ));
  //   }

  //   return toReturn;
  // }

  Future<ClassTableData> getEhall() async {
    Map<String, dynamic> qResult = {};
    log.info("[getClasstable][getEhall] Login the system.");
    await useJwxt();

    log.info(
      "[getClasstable][getEhall] "
      "Fetch the semester information.",
    );
    DateTime now = DateTime.now();
    var month = "${now.year}-${now.month.toString().padLeft(2, '0')}";
    String semesterCode = await dioEhall
        .post(
          "https://jwxt.gxmu.edu.cn/new/curMonthXnxq",
          data: "month=$month",
        )
        .then((value) => value.data['data'][0]['xnxqdm']);
    if (preference.getString(preference.Preference.currentSemester) !=
        semesterCode) {
      preference.setString(
        preference.Preference.currentSemester,
        semesterCode,
      );

      /// New semenster, user defined class is useless.
      var userClassFile = File("${supportPath.path}/$userDefinedClassName");
      if (userClassFile.existsSync()) userClassFile.deleteSync();
    }

    log.info(
      "[getClasstable][getEhall] "
      "Fetch the day the semester begin.",
    );

    String termStartDay = await dioEhall
        .post(
          "https://jwxt.gxmu.edu.cn/new/xlxx/data",
          data: "xnxqdm=$semesterCode",
        )
        .then((value) => value.data['data'][0][1][1]['fullText']);
    termStartDay += ' 00:00:00'; // Add time to the date

    log.info(
      "[getClasstable][getEhall] "
      "Current semester is $semesterCode, term start day is $termStartDay.",
    );
    // 获取当前日期是星期几
    int weekday = now.weekday;
    // 计算距离本周一的偏移天数
    int offsetToMonday = weekday - 1;
    // 计算距离本周日的偏移天数
    int offsetToSunday = 7 - weekday;
    // 获取本周一的日期
    DateTime monday = now.subtract(Duration(days: offsetToMonday));
    // 获取本周日的日期
    DateTime sunday = now.add(Duration(days: offsetToSunday));
    // 格式化日期
    String mondayStr =
        "${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')} 00:00:00";
    String sundayStr =
        "${sunday.year}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')} 00:00:00";
    qResult = await dioEhall.post(
      'https://jwxt.gxmu.edu.cn/new/student/xsgrkb/getCalendarWeekDatas',
      data: {
        "xnxqdm": semesterCode, // 当前学期
        "zc": "",
        "d1": mondayStr, // 开始时间
        "d2": sundayStr, // 结束时间
      },
    ).then((value) => value.data);

    if (qResult['code'] != 0) {
      log.warning("[getClasstable][getJwxt] "
          "extParams: ${qResult['message']} isNotPublish: ");
      if (qResult['message'].toString().contains("本学期课表未开放")) {
        return ClassTableData(
          semesterCode: semesterCode,
          termStartDay: termStartDay,
        );
      } else {
        throw Exception("${qResult['message']}");
      }
    }

    log.info(
      "[getClasstable][getEhall] "
      "Preliminary storage...",
    );
    qResult["semesterCode"] = semesterCode;
    qResult["termStartDay"] = termStartDay;

    /* var notOnTable = await dioEhall.post(
      "https://ehall.xidian.edu.cn/jwapp/sys/wdkb/modules/xskcb/cxxsllsywpk.do",
      data: {
        'XNXQDM': semesterCode,
        'XH': preference.getString(preference.Preference.idsAccount),
      },
    ).then((value) => value.data['datas']['cxxsllsywpk']); */

    ClassTableData preliminaryData = simplifyData(qResult); // simplify the data

    return preliminaryData;
  }
}

class NotSameSemesterException implements Exception {
  final String msg;
  NotSameSemesterException({required this.msg});
}
