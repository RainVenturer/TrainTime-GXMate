// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/repository/gxmu_ids/jwxt_session.dart';
import 'package:watermeter/repository/captcha/captcha_solver.dart';

class PersonalInfoSession extends JwxtSession {
  // Future<String> getInformationFromYjspt({bool onlyPhone = false}) async {
  //   String location = await checkAndLogin(
  //     target: "https://yjspt.xidian.edu.cn/",
  //     sliderCaptcha: (String cookieStr) =>
  //         SliderCaptchaClientProvider(cookie: cookieStr).solve(null),
  //   );

  //   log.info(
  //     "[PersonalInfoSession][getInformationFromYjspt] "
  //     "Location is $location",
  //   );
  //   var response = await dio.get(location);
  //   while (response.headers[HttpHeaders.locationHeader] != null) {
  //     location = response.headers[HttpHeaders.locationHeader]![0];
  //     log.info(
  //       "[PersonalInfoSession][getInformationFromYjspt] "
  //       "Received location: $location.",
  //     );
  //     response = await dio.get(location);
  //   }

  //   log.info(
  //     "[PersonalInfoSession][getInformationFromYjspt] "
  //     "Getting the user information.",
  //   );
  //   var detailed = await dio
  //       .post(
  //         "https://yjspt.xidian.edu.cn/gsapp/sys/yjsemaphome/modules/pubWork/getUserInfo.do",
  //       )
  //       .then((value) => value.data);
  //   if (onlyPhone == false) {
  //     if (detailed["code"] != "0") {
  //       throw GetInformationFailedException(detailed["msg"].toString());
  //     }
  //     preference.setString(
  //       preference.Preference.name,
  //       detailed["data"]["userName"],
  //     );
  //     preference.setString(
  //       preference.Preference.currentSemester,
  //       detailed["data"]["xnxqdm"],
  //     );
  //   }

  //   detailed = await dio
  //       .post(
  //         "https://yjspt.xidian.edu.cn/gsapp/sys/yjsemaphome/homeAppendPerson/getXsjcxx.do",
  //         data: {"datas": '{"wdxysysfaxq":"1","concurrency":"main"}'},
  //         options: Options(
  //           contentType: "application/x-www-form-urlencoded; charset=UTF-8",
  //         ),
  //       )
  //       .then((value) => value.data);
  //   log.info(
  //     "[PersonalInfoSession][getInformationFromYjspt] "
  //     "Storing the user information.",
  //   );
  //   if (onlyPhone == false) {
  //     preference.setString(
  //       preference.Preference.execution,
  //       "", //detailed["performance"][0]["CONTENT"][4]["CAPTION"],
  //     );
  //     preference.setString(
  //       preference.Preference.institutes,
  //       "", //detailed["performance"][0]["CONTENT"][2]["CAPTION"],
  //     );
  //     preference.setString(
  //       preference.Preference.subject,
  //       "", //detailed["performance"][0]["CONTENT"][3]["CAPTION"],
  //     );
  //     preference.setString(
  //       preference.Preference.dorm,
  //       "", // Did not return, use false data
  //     );
  //     log.info(
  //       "[ehall_session][getInformation] "
  //       "Get the day the semester begin.",
  //     );

  //     log.info(
  //       "[ehall_session][getInformation] "
  //       "Get the semester information.",
  //     );
  //     String? location = await checkAndLogin(
  //       target: "https://yjspt.xidian.edu.cn/gsapp/"
  //           "sys/wdkbapp/*default/index.do#/xskcb",
  //       sliderCaptcha: (String cookieStr) =>
  //           SliderCaptchaClientProvider(cookie: cookieStr).solve(null),
  //     );

  //     while (location != null) {
  //       var response = await dio.get(location);
  //       log.info("[getClasstable][getYjspt] Received location: $location.");
  //       location = response.headers[HttpHeaders.locationHeader]?[0];
  //     }

  //     var semesterCode = await dio
  //         .post(
  //           "https://yjspt.xidian.edu.cn/gsapp/sys/wdkbapp/modules/xskcb/kfdxnxqcx.do",
  //         )
  //         .then((value) => value.data["datas"]["kfdxnxqcx"]["rows"][0]["WID"]);
  //     preference.setString(
  //       preference.Preference.currentSemester,
  //       semesterCode,
  //     );
  //   }

  //   return "02981891206";
  // }

  /// 学生个人信息
  /// Return phone info for electricity. set onlyPhone to avoid update
  /// personal info.
  Future<String> getInformationEhall({bool onlyPhone = false}) async {
    log.info(
      "[Jwxt_session][getInformation] "
      "Ready to get the user information.",
    );

    String location = await super.checkAndLogin(
      target: "https://jwxt.gxmu.edu.cn",
      codeCaptcha: (List<int> image, DigitCaptchaType type, bool isLogin) =>
          DigitCaptchaClientProvider.solve(null, image, type, isLogin),
    );
    log.info("[Jwxt_session][useApp] "
        "Location is $location");
    var response = await dio.get(
      location,
      options: Options(headers: {
        HttpHeaders.refererHeader: "https://jwxt.gxmu.edu.cn",
        HttpHeaders.hostHeader: "jwxt.gxmu.edu.cn",
      }),
    );
    while (response.headers[HttpHeaders.locationHeader] != null) {
      location = response.headers[HttpHeaders.locationHeader]![0];
      log.info(
        "[Jwxt_session][useApp] "
        "Received location: $location.",
      );
      response = await dioEhall.get(
        location,
        options: Options(headers: {
          HttpHeaders.refererHeader: "https://jwxt.gxmu.edu.cn/new/desktop",
          HttpHeaders.hostHeader: "jwxt.gxmu.edu.cn",
        }),
      );
    }

    /// Get information here. resultCode==00000 is successful.
    log.info(
      "[Jwxt_session][getInformation] "
      "Getting the user information.",
    );
    var detailed = await dioEhall
        .get("https://jwxt.gxmu.edu.cn/new/student/xjkpxx/edit.page",
            queryParameters: {
              "confirmInfo": null,
            },
            options: Options(headers: {
              HttpHeaders.refererHeader:
                  "https://jwxt.gxmu.edu.cn/new/student/xjkpxx",
              HttpHeaders.hostHeader: "jwxt.gxmu.edu.cn",
            }))
        .then(
          (value) => value.data,
        );
    log.info(
      "[Jwxt_session][getInformation] "
      "Storing the user information.",
    );
    if (onlyPhone == false) {
      if (detailed is Map<String, dynamic>) {
        throw GetInformationFailedException(detailed["description"]);
      } else {
        // 定义要查找的字段映射
        final fieldMap = {
          '姓名：': '',
          '所在校区：': '',
          '班级：': '',
          '院系名称：': '',
          '专业：': '',
        };
        var document = parse(detailed);
        var labelTds = document.querySelectorAll('td label');
        for (var label in labelTds) {
          var parentTd = label.parent;
          if (parentTd == null) continue;

          var previousTd = parentTd.previousElementSibling;
          if (previousTd == null) continue;

          var key = previousTd.text.trim();
          if (fieldMap.containsKey(key)) {
            fieldMap[key] = label.text.trim();
          }
        }

        preference.setString(
          preference.Preference.name,
          fieldMap['姓名：'] ?? '',
        );
        preference.setBool(
          preference.Preference.isInHeadQuarters,
          fieldMap['所在校区：']?.contains('本部') ?? false,
        );
        preference.setString(
          preference.Preference.idCardSix,
          document
                  .querySelector("#sfzh")
                  ?.attributes['value']
                  .toString()
                  .substring(12, 18) ??
              "",
        );
        preference.setString(
          preference.Preference.institutes,
          fieldMap['院系名称：'] ?? '',
        );
        preference.setString(
          preference.Preference.subject,
          fieldMap['专业：'] ?? '',
        );
        preference.setString(
          preference.Preference.classString,
          fieldMap['班级：'] ?? '',
        );
      }

      log.info(
        "[Jwxt_session][getInformation] "
        "Get the semester information.",
      );
      //TODO: check if this is correct
      DateTime now = DateTime.now();
      var month = "${now.year}-${now.month.toString().padLeft(2, '0')}";
      String semesterCode = await dioEhall
          .post(
            "https://jwxt.gxmu.edu.cn/new/curMonthXnxq",
            data: "month=$month",
          )
          .then((value) => value.data['data'][0]['xnxqdm']);
      preference.setString(
        preference.Preference.currentSemester,
        semesterCode,
      );
    }

    return "02981891206";
  }
}
