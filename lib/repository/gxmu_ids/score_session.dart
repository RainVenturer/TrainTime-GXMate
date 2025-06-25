// Copyright 2023 BenderBlog Rodriguez and contributors.
// SPDX-License-Identifier: MPL-2.0

// The score window source.
// Thanks xidian-script and libxdauth!

// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';

// import 'package:watermeter/page/login/jc_captcha.dart';
// import 'package:watermeter/repository/preference.dart' as pref;
import 'package:watermeter/model/gxmu_ids/score.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/gxmu_ids/jwxt_session.dart';
import 'package:html/parser.dart';

/// 考试成绩
class ScoreSession extends JwxtSession {
  static const scoreListCacheName = "scores.json";
  static File file = File("${supportPath.path}/$scoreListCacheName");
  static bool isScoreListCacheUsed = false;

  static bool get isCacheExist => file.existsSync();

  /// Must be called after [getScore]!
  /// If bug, just return dummy data.
  Future<List<ComposeDetail>> getDetail(
    int? CJDM,
  ) async {
    if (CJDM == null) {
      return [
        ComposeDetail(
          content: "教学班编号",
          ratio: "未知",
          score: "无法查询",
        )
      ];
    }

    try {
      List<ComposeDetail> toReturn = [];
      log.info(
        "[ScoreSession][getDetail] isScoreListCacheUsed $isScoreListCacheUsed.",
      );

      if (isScoreListCacheUsed) {
        log.info(
          "[ScoreSession][getDetail] Cache detected, need login.",
        );

        if (!await isLoggedIn()) {
          await useJwxt();
        }
      }

      var response = await dioEhall
          .post("https://jwxt.gxmu.edu.cn/new/student/xskccj/getDetail", data: {
        "cjdm": CJDM,
      }).then((value) => value.data);

      if (response["code"] != -401) {
        final data = response["data"][0];
        Map<String, String> formula = {
          "平时成绩": data["bl1"].toString(),
          "实验成绩": data["bl2"].toString(),
          "期中考核": data["bl3"].toString(),
          "期末成绩": data["bl4"].toString(),
          "实践成绩": data["bl5"].toString(),
        };
        Map<String, String> detail = {
          "平时成绩": data["cj1"].toString(),
          "实验成绩": data["cj2"].toString(),
          "期中考核": data["cj3"].toString(),
          "期末成绩": data["cj4"].toString(),
          "实践成绩": data["cj5"].toString(),
        };
        // Create a list to store keys that need to be removed
        final keysToRemove = <String>[];
        for (var i in detail.keys) {
          if (detail[i]!.isEmpty || detail[i] == "") {
            keysToRemove.add(i);
          }
        }
        // Remove the keys after iteration
        for (var key in keysToRemove) {
          formula.remove(key);
          detail.remove(key);
        }

        for (var i in formula.keys) {
          toReturn.add(
            ComposeDetail(
              content: i,
              ratio: "${(formula[i] ?? '') == '' ? '100' : formula[i]}%",
              score: detail[i] ?? '未登记',
            ),
          );
        }
      }

      return toReturn;
    } catch (e, s) {
      log.info(
        "[ScoreSession] Fetch detail error: $e $s.",
      );

      return [
        ComposeDetail(
          content: "获取详情失败",
          ratio: "",
          score: "",
        )
      ];
    }
  }

  /// Must be called after [getScore]!
  /// If bug, just return dummy data.
  Future<List<ComposeAnalyze>> getAnalyze(String? CJDM) async {
    List<ComposeAnalyze> toReturn = [];
    if (CJDM == null) {
      return [
        ComposeAnalyze(
          type: "无法查询",
          name: "无法查询",
          scoreDsitribution: {},
          total: 0,
          rank: 0,
        )
      ];
    }

    int safeint(String? value) {
      // 转换为整数，如果为空则返回0
      try {
        return value?.trim().isEmpty == false ? int.parse(value!.trim()) : 0;
      } catch (e) {
        return 0;
      }
    }

    try {
      log.info(
        "[ScoreSession][getAnalyze] isScoreListCacheUsed $isScoreListCacheUsed.",
      );

      if (isScoreListCacheUsed) {
        log.info(
          "[ScoreSession][getAnalyze] Cache detected, need login.",
        );

        if (!await isLoggedIn()) {
          await useJwxt();
        }
      }

      var response = await dioEhall.get(
        "https://jwxt.gxmu.edu.cn/new/student/xskccj/kccjfxd.page",
        queryParameters: {
          "cjdm": CJDM,
        },
      );

      // 使用 BeautifulSoup 类似的方式解析 HTML
      var document = parse(response.data);
      var table = document.querySelector('table');

      if (table == null) {
        throw Exception("无法找到成绩分析表格");
      }

      var rows = table.querySelectorAll('tr');

      for (var row in rows.skip(1)) {
        // 跳过表头
        var cols = row.querySelectorAll('td');
        if (cols.isEmpty) continue;

        toReturn.add(ComposeAnalyze(
          type: cols[0].text.trim(),
          name: cols[1].text.trim(),
          scoreDsitribution: Map.fromIterables(
            ['60分以下', '60-70分', '70-80分', '80-90分', '90分以上'],
            cols.skip(2).take(5).map((e) => safeint(e.text.trim())),
          ),
          total: safeint(cols[7].text.trim()),
          rank: safeint(cols[8].text.trim()),
        ));
      }

      return toReturn;
    } catch (e, s) {
      log.info(
        "[ScoreSession] Fetch analyze error: $e $s.",
      );

      return [
        ComposeAnalyze(
          type: "无法查询",
          name: "无法查询",
          scoreDsitribution: {},
          total: 0,
          rank: 0,
        )
      ];
    }
  }

  void dumpScoreListCache(List<Score> scores) {
    file.writeAsStringSync(jsonEncode(scores));
    log.info(
      "[ScoreWindow][dumpScoreListCache] "
      "Dumped scoreList to ${supportPath.path}/$scoreListCacheName.",
    );
  }

  // Future<List<Score>> getScoreFromYjspt() async {
  //   List<Score> toReturn = [];

  //   log.info("[ScoreSession][getScoreFromYjspt] Ready to login the system.");
  //   String? location = await checkAndLogin(
  //     target: "https://yjspt.xidian.edu.cn/gsapp/sys/wdcjapp/*default/index.do",
  //     sliderCaptcha: (String cookieStr) =>
  //         SliderCaptchaClientProvider(cookie: cookieStr).solve(null),
  //   );

  //   while (location != null) {
  //     var response = await dio.get(location);
  //     log.info("[ExamFile][getScoreFromYjspt] Received location: $location.");
  //     location = response.headers[HttpHeaders.locationHeader]?[0];
  //   }

  //   log.info("[ScoreSession][getScoreFromYjspt] Getting the score data.");
  //   var getData = await dio.post(
  //     "https://yjspt.xidian.edu.cn/gsapp/sys/wdcjapp/modules/wdcj/xscjcx.do",
  //     data: {
  //       "querySetting": [],
  //       'pageSize': 1000,
  //       'pageNumber': 1,
  //     },
  //   ).then((value) => value.data);

  //   log.info("[ScoreSession][getScoreFromYjspt] Dealing the score data.");
  //   if (getData["datas"]["xscjcx"]["extParams"]["code"] != 1) {
  //     throw GetScoreFailedException(
  //         getData['datas']['xscjcx']["extParams"]["msg"]);
  //   }
  //   int j = 0;
  //   for (var i in getData['datas']['xscjcx']['rows']) {
  //     toReturn.add(Score(
  //       mark: j,
  //       name: "${i["KCMC"]}",
  //       score: i["DYBFZCJ"],
  //       semesterCode: i["XNXQDM_DISPLAY"],
  //       credit: i["XF"],
  //       classStatus: i["KCLBMC"],
  //       scoreTypeCode: int.parse(i["CJFZDM"]),
  //       level: i["CJFZDM"] != "0" ? i["CJXSZ"] : null,
  //       isPassedStr: i["SFJG"].toString(),
  //       classID: i["KCDM"],
  //       classType: i['KCLBMC'],
  //       scoreStatus: i["KSXZDM_DISPLAY"],
  //     ));
  //     j++;
  //   }
  //   return toReturn;
  // }

  Future<List<Score>> getCourseScoreFromJwxt() async {
    List<Score> toReturn = [];
    if (!await isLoggedIn()) {
      await useJwxt();
    }

    /// Otherwise get fresh score data.
    Map<String, dynamic> querySetting = {
      'xnxqdm': '',
      'source': 'kccjlist',
      'jhlxdm': '',
      'ismax': '',
      'page': '1',
      'rows': '1000',
      'sort': 'xnxqdm,kcmc',
      'order': 'desc,asc',
    };
    log.info(
      "[ScoreSession][getScoreFromJWXT] "
      "Ready to log into the system.",
    );

    log.info(
      "[ScoreSession][getScoreFromJWXT] "
      "Getting score data.",
    );
    var getData = await dioEhall
        .post(
          "https://jwxt.gxmu.edu.cn/new/student/xskccj/kccjDatas",
          data: querySetting,
        )
        .then((value) => value.data);
    log.info(
      "[ScoreSession][getScoreFromJWXT] "
      "Dealing with the score data.",
    );
    if (getData['code'] == -401) {
      throw GetScoreFailedException(
        getData['message'],
      );
    }
    int j = 0;
    for (var i in getData['rows']) {
      toReturn.add(Score(
        mark: j,
        name: i["kcmc"], // 课程名
        score: i["zcjfs"], // 总成绩
        gradePoint: i["cjjd"], // 绩点
        semesterCode: i["xnxqmc"], // 学年学期代码，如 2024-2025-1
        credit: i["xf"], // 学分
        classStatus: i["xdfsmc"], // 课程性质，必修，选修等
        classType: i["kcdlmc"], // 课程类别，公共任选，素质提高等
        scoreStatus: i["ksxzmc"], // 正常考试、补考1、重修重考等
        scoreType: i["cjfsmc"], // 等级成绩类型，百分制等（？）
        scoreCode: int.parse(i["cjdm"]), // 成绩代码
        isMax: i["ismax"] == '1', // 是否为最大成绩
        isPassedStr: i["zcjfs"] >= 60 ? "1" : "0", // 是否及格
        isLevel: false,
      ));
      j++;
    }
    return toReturn;
  }

  Future<List<Score>> getLevelScoreFromJwxt(List<Score> toReturn) async {
    /// Otherwise get fresh score data.
    Map<String, dynamic> querySetting = {
      'page': '1',
      'rows': '100',
      'sort': 'xnxqdm',
      'order': 'asc',
    };
    log.info(
      "[ScoreSession][getScoreFromJWXT] "
      "Ready to log into the system.",
    );

    log.info(
      "[ScoreSession][getScoreFromJWXT] "
      "Getting score level data.",
    );
    var getData = await dioEhall
        .post(
          "https://jwxt.gxmu.edu.cn/new/student/xskjcj/datas",
          data: querySetting,
        )
        .then((value) => value.data);
    log.info(
      "[ScoreSession][getLevelScoreFromJWXT] "
      "Dealing with the score data.",
    );
    if (getData['code'] == -401) {
      throw GetScoreFailedException(
        getData['message'],
      );
    }
    int j = toReturn.length;
    for (var i in getData['rows']) {
      toReturn.add(Score(
        mark: j,
        name: i["kjkcmc"], // 课程名
        score: i["zcj"], // 总成绩
        gradePoint: 0.00, // 绩点
        semesterCode: i["xnxqmc"], // 学年学期代码，如 2024-2025-1
        credit: 0.00, // 学分
        classStatus: '', // 课程性质，必修，选修等
        classType: '', // 课程类别，公共任选，素质提高等
        scoreStatus: '', // 正常考试、补考1、重修重考等
        scoreType: '', // 等级成绩类型，百分制等（？）
        scoreCode: null, // 成绩代码
        isMax: false, // 是否为最大成绩
        isPassedStr: i["zcj"] >= 425 ? '1' : '0', // 是否及格
        isLevel: true,
      ));
      j++;
    }
    return toReturn;
  }

  Future<List<Score>> getScore({bool force = false}) async {
    List<Score> toReturn = [];
    List<Score> cache = [];

    /// Try retrieving cached scores first.
    log.info(
      "[ScoreSession][getScore] "
      "Path at ${supportPath.path}/$scoreListCacheName.",
    );
    if (file.existsSync() && !force) {
      final timeDiff =
          DateTime.now().difference(file.lastModifiedSync()).inMinutes;
      log.info(
        "[ScoreSession][getScore] "
        "Cache file found.",
      );
      cache = (jsonDecode(file.readAsStringSync()) as List<dynamic>)
          .map((s) => Score.fromJson(s as Map<String, dynamic>))
          .toList();
      if (cache.isNotEmpty && timeDiff < 15) {
        isScoreListCacheUsed = true;
        log.info(
          "[ScoreSession][getScore] "
          "Loaded scores from cache. Timediff: $timeDiff."
          " isScoreListCacheUsed $isScoreListCacheUsed",
        );
        return cache;
      }
    } else {
      log.info(
        "[ScoreSession][getScore] "
        "Cache file non-existent.",
      );
    }

    /// Otherwise get fresh score data.
    log.info(
      "[ScoreSession][getScore] "
      "Start getting score data.",
    );

    try {
      toReturn = await getCourseScoreFromJwxt();
      toReturn = await getLevelScoreFromJwxt(toReturn);
      dumpScoreListCache(toReturn);
      log.info(
        "[ScoreSession][getScore] "
        "Cached the score data.",
      );
      isScoreListCacheUsed = false;
      return toReturn;
    } catch (e) {
      if (cache.isNotEmpty) {
        isScoreListCacheUsed = true;
        log.info(
          "[ScoreSession][getScore] "
          "Loaded scores from cache. isScoreListCacheUsed "
          "$isScoreListCacheUsed. Error: $e.",
        );
        return cache;
      } else {
        rethrow;
      }
    }
  }
}

class GetScoreFailedException implements Exception {
  final String msg;
  const GetScoreFailedException(this.msg);

  @override
  String toString() => msg;
}

Map<String, String> scoreRatio = {
  "bl1": "平时成绩",
  "bl2": "实验成绩",
  "bl3": "期中考核",
  "bl4": "期末成绩",
  "bl5": "实践成绩",
};

Map<String, String> scoreType = {
  "cj1": "平时成绩",
  "cj2": "实验成绩",
  "cj3": "期中考核",
  "cj4": "期末成绩",
  "cj5": "实践成绩",
};
