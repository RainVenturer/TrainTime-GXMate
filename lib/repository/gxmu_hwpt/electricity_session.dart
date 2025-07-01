// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

// Get payment, specifically your owe.

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:watermeter/model/gxmu_ids/electricity.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/repository/gxmu_hwpt/hwpt_session.dart';

var historyElectricityInfo = RxList<ElectricityInfo>();
var electricityInfo = ElectricityInfo.empty(DateTime.now()).obs;
var isCache = false.obs;
var isLoad = false.obs;

extension IsToday on DateTime {
  bool get isToday {
    DateTime now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
}

Future<void> update({
  bool force = false,
}) async {
  isLoad.value = true;
  isCache.value = false;
  electricityInfo.value.fetchDay = DateTime.now();

  late ElectricityInfo cache;
  bool canUseCache = false;

  if (ElectricitySession.isCacheExist) {
    try {
      cache = ElectricityInfo.fromJson(
        jsonDecode(ElectricitySession.fileCache.readAsStringSync()),
      );
      canUseCache = true;
    } catch (e, s) {
      log.handle(e, s);
      canUseCache = false;
    }
  }

  if (!force && canUseCache && cache.fetchDay.isToday) {
    ElectricitySession.refreshElectricityHistory(cache);
    electricityInfo.value = cache;
    isCache.value = true;
    isLoad.value = false;
    return;
  }

  log.info(
    "[ElectricitySession][update]"
    "Fetching electricity info...",
  );

  Future(() async {
    try {
      await ElectricitySession().getElectricity();
    } on DioException catch (e, s) {
      log.handle(e, s);
      electricityInfo.value.remain = "electricity_status.remain_network_issue";
    } on NotFoundException {
      electricityInfo.value.remain = "electricity_status.location_not_found";
    } catch (e, s) {
      log.handle(e, s);
      electricityInfo.value.remain = "electricity_status.remain_other_issue";
    }
  }).then((value) async {
    if (ElectricitySession.isCacheExist) {
      await ElectricitySession.fileCache.create();
    }
    ElectricitySession.fileCache.writeAsStringSync(
      jsonEncode(electricityInfo.value.toJson()),
    );
    ElectricitySession.refreshElectricityHistory(electricityInfo.value);
  }).catchError(
    (e, s) {
      log.handle(e, s);
      if (canUseCache) {
        electricityInfo.value = cache;
        isCache.value = true;
        isLoad.value = false;
        return;
      }
    },
  );
  // await ElectricitySession()
  //     .loginPayment(captchaFunction: captchaFunction)
  //     .then(
  //       (value) => Future.wait([
  //         Future(() async {
  //           try {
  //             electricityInfo.value.remain =
  //                 "electricity_status.remain_fetching";
  //             await ElectricitySession().getElectricity(value);
  //           } on DioException catch (e, s) {
  //             log.handle(e, s);
  //             electricityInfo.value.remain =
  //                 "electricity_status.remain_network_issue";
  //           } on NotFoundException {
  //             electricityInfo.value.remain =
  //                 "electricity_status.remain_not_found";
  //           } catch (e, s) {
  //             log.handle(e, s);
  //             electricityInfo.value.remain =
  //                 "electricity_status.remain_other_issue";
  //           }
  //         }),
  //         Future(() async {
  //           try {
  //             electricityInfo.value.owe = "electricity_status.owe_fetching";
  //             await ElectricitySession().getOwe(value);
  //           } on DioException {
  //             log.info(
  //               "[PaymentSession][update] "
  //               "Network error",
  //             );
  //             electricityInfo.value.owe = "electricity_status.owe_issue";
  //           } catch (e, s) {
  //             log.handle(e, s);
  //             electricityInfo.value.owe = "electricity_status.owe_not_found";
  //           }
  //         })
  //       ]).then((value) async {
  //         if (ElectricitySession.isCacheExist) {
  //           await ElectricitySession.fileCache.create();
  //         }
  //         ElectricitySession.fileCache.writeAsStringSync(
  //           jsonEncode(electricityInfo.value.toJson()),
  //         );
  //         ElectricitySession.refreshElectricityHistory(electricityInfo.value);
  //       }),
  //     )
  //     .catchError(
  //   (e, s) {
  //     log.handle(e, s);
  //     if (canUseCache) {
  //       electricityInfo.value = cache;
  //       isCache.value = true;
  //       isLoad.value = false;
  //       return;
  //     }

  //     if (NeedInfoException().toString().contains(e.toString())) {
  //       electricityInfo.value.remain = "electricity_status.need_more_info";
  //     } else if ("NotInitalizedException".contains(e.toString())) {
  //       electricityInfo.value.remain = e.msg;
  //     } else if (NoAccountInfoException().toString().contains(e.toString())) {
  //       electricityInfo.value.remain = "electricity_status.need_account";
  //     } else if (CaptchaFailedException().toString().contains(e.toString())) {
  //       electricityInfo.value.remain = "electricity_status.captcha_failed";
  //     } else {
  //       electricityInfo.value.remain = "electricity_status.other_issue";
  //     }
  //     if (electricityInfo.value.owe == "electricity_status.owe_fetching" ||
  //         electricityInfo.value.owe == "electricity_status.pending") {
  //       electricityInfo.value.owe = "electricity_status.owe_issue_unable";
  //     }
  //   },
  // );
  isLoad.value = false;
}

class ElectricitySession extends HWPTSession {
  static const factorycode = "E003";
  static const electricityCache = "Electricity.json";
  static const electricityHistory = "ElectricityHistory.json";
  static File fileCache = File("${supportPath.path}/$electricityCache");
  static File fileHistory = File("${supportPath.path}/$electricityHistory");
  static final regex = RegExp(r'value="(CfDJ8[\w\-+/=]+)"');

  static bool get isCacheExist => fileCache.existsSync();

  /// This header shall only be used in the 智慧公寓 related stuff...
  Map<String, String> refererHeaderZHGY = {
    HttpHeaders.refererHeader: "https://gyglxt.gxmu.edu.cn/app/",
    HttpHeaders.hostHeader: "gyglxt.gxmu.edu.cn",
    HttpHeaders.acceptHeader: "application/json, text/plain, */*",
    HttpHeaders.acceptLanguageHeader:
        'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
    HttpHeaders.acceptEncodingHeader: 'gzip, deflate, br, zstd',
    HttpHeaders.connectionHeader: 'Keep-Alive',
    HttpHeaders.contentTypeHeader: "application/json;charset=UTF-8",
    HttpHeaders.userAgentHeader:
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/130.0.0.0 Safari/537.36",
  };

  Dio get dioZHGY =>
      super.dio..options = BaseOptions(headers: refererHeaderZHGY);

  /// This header shall only be used in the 本部电费 related stuff...
  Map<String, String> refererHeadersYDFWPT = {
    HttpHeaders.hostHeader: "ydfwpt.gxmu.edu.cn",
    HttpHeaders.acceptHeader: "application/json, text/javascript, */*; q=0.01",
    // "origin": "https://ydfwpt.gxmu.edu.cn",
    HttpHeaders.acceptLanguageHeader:
        'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
    HttpHeaders.acceptEncodingHeader: 'gzip, deflate, br, zstd',
    HttpHeaders.connectionHeader: 'Keep-Alive',
    HttpHeaders.contentTypeHeader:
        "application/x-www-form-urlencoded; charset=UTF-8",
    HttpHeaders.userAgentHeader:
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/130.0.0.0 Safari/537.36",
  };

  Dio get dioYDFWPT =>
      super.dio..options = BaseOptions(headers: refererHeadersYDFWPT);

  /// This header shall only be used in the 武鸣电费 related stuff...
  Map<String, String> refererHeadersXFEWM = {
    HttpHeaders.hostHeader: "xfewm.gxmu.edu.cn",
    HttpHeaders.refererHeader: "http://xfewm.gxmu.edu.cn/MobilePayWeb/",
    HttpHeaders.acceptHeader: "application/json, text/javascript, */*; q=0.01",
    HttpHeaders.acceptLanguageHeader:
        'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
    HttpHeaders.acceptEncodingHeader: 'gzip, deflate, br, zstd',
    HttpHeaders.connectionHeader: 'Keep-Alive',
    HttpHeaders.contentTypeHeader:
        "application/x-www-form-urlencoded; charset=UTF-8",
    HttpHeaders.userAgentHeader: "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"
        "AppleWebKit/537.36 (KHTML, like Gecko)"
        "Chrome/126.0.0.0 Safari/537.36 NetType/WIFI"
        "MicroMessenger/7.0.20.1781(0x6700143B)"
        "WindowsWechat(0x63090c33) XWEB/13907 Flue",
  };

  Dio get dioXFEWM =>
      super.dio..options = BaseOptions(headers: refererHeadersXFEWM);

  // Read the cached list
  // Input an electricity info will refresh the list
  static void refreshElectricityHistory(ElectricityInfo? info) {
    if (!ElectricitySession.fileHistory.existsSync()) {
      ElectricitySession.fileHistory.createSync();
    }

    var list = <ElectricityInfo>[];
    try {
      List proto =
          jsonDecode(ElectricitySession.fileHistory.readAsStringSync());
      list.clear();
      list.addAll(List<ElectricityInfo>.generate(
          proto.length, (data) => ElectricityInfo.fromJson(proto[data])));
    } catch (e, s) {
      log.handle(e, s);
    }

    if (info != null) {
      if (list.length > 7) {
        list.removeAt(0);
      }
      if (!(list.isNotEmpty &&
          list.last.fetchDay.year == info.fetchDay.year &&
          list.last.fetchDay.month == info.fetchDay.month &&
          list.last.fetchDay.day == info.fetchDay.day &&
          list.last.remain == info.remain)) {
        list.add(info);
        fileHistory.writeAsStringSync(jsonEncode(list));
      }
    }

    historyElectricityInfo.clear();
    historyElectricityInfo.addAll(list);
  }

  // Future<void> getElectricity((String, String) fetched) => dio.post(
  //       "https://payment.xidian.edu.cn/NetWorkUI/checkPayelec",
  //       data: {
  //         "addressid": fetched.$1,
  //         "liveid": fetched.$2,
  //         'payAmt': 'leftwingpopulism',
  //         "factorycode": factorycode,
  //       },
  //     ).then((value) {
  //       var decodeData = jsonDecode(value.data);
  //       if (decodeData["returnmsg"] == "连接超时") {
  //         double balance = double.parse(
  //             decodeData["rtmeterInfo"]["Result"]["Meter"]["RemainQty"]);
  //         electricityInfo.value.remain = balance.toString();
  //       } else {
  //         throw NotFoundException();
  //       }
  //     });

  /// 获取宿舍电费 本部: appId: 215093e432424d0ea21ed98a27e93d61
  Future<void> getElectricity() async {
    List<String> location = [];
    if (preference.getString(preference.Preference.location).isEmpty) {
      location = getLocation(
        preference.getString(preference.Preference.dorm),
      );
      log.info(
        "[ElectricitySession][getElectricity]"
        "Location auto get: $location",
      );
    } else {
      location =
          preference.getString(preference.Preference.location).split("/");
      log.info(
        "[ElectricitySession][getElectricity]"
        "Location user edit: $location",
      );
    }

    if (preference.getString(preference.Preference.dorm).contains("本部")) {
      /// ----------------------------------------
      /// 获取本部宿舍电量
      /// ----------------------------------------
      var response = await useApp("215093e432424d0ea21ed98a27e93d61");

      /// 获取 referer
      var referer = response.$1;

      /// 获取学生学号
      final document = parse(response.$2.data);
      final studentNumberInput = document.querySelector('#StudentNumber');
      final studentNumber = studentNumberInput!.attributes['value']!;

      /// 获取 requestVerificationToken
      final requestVerificationToken =
          regex.firstMatch(response.$2.data)!.group(1)!;

      var firstLevel = await dioYDFWPT
          .post(
            "https://ydfwpt.gxmu.edu.cn/Home/GetRoomTree",
            data: {
              "level": "1",
              "studentNumber": studentNumber,
              "__RequestVerificationToken": requestVerificationToken,
            },
            options: Options(headers: {
              ...refererHeadersYDFWPT,
              HttpHeaders.refererHeader: referer,
            }),
          )
          .then((value) => value.data);
      var dataModel = firstLevel['dataModel'] as List;
      Map<String, String> choiceListsLevel1 = Map<String, String>.fromEntries(
        dataModel.map((item) => MapEntry(item['name'], item['code'])),
      );
      var secondLevel = await dioYDFWPT
          .post(
            "https://ydfwpt.gxmu.edu.cn/Home/GetRoomTree",
            data: {
              "level": 2,
              "campusCode": choiceListsLevel1["本校区"]!,
              "studentNumber": studentNumber,
              "__RequestVerificationToken": requestVerificationToken,
            },
            options: Options(
              headers: {
                ...refererHeadersYDFWPT,
                HttpHeaders.refererHeader: referer,
              },
            ),
          )
          .then((value) => value.data);
      dataModel = secondLevel['dataModel'] as List;
      Map<String, String> choiceListsLevel2 = Map<String, String>.fromEntries(
        dataModel.map((item) => MapEntry(item['name'], item['code'])),
      );
      var thirdLevel = await dioYDFWPT
          .post(
            "https://ydfwpt.gxmu.edu.cn/Home/GetRoomTree",
            data: {
              "level": 3,
              "campusCode": choiceListsLevel1["本校区"]!,
              "buildingCode": choiceListsLevel2[location[0]]!,
              "studentNumber": studentNumber,
              "__RequestVerificationToken": requestVerificationToken,
            },
            options: Options(
              headers: {
                HttpHeaders.refererHeader: referer,
              },
            ),
          )
          .then((value) => value.data);
      dataModel = thirdLevel['dataModel'] as List;
      Map<String, String> choiceListsLevel3 = Map<String, String>.fromEntries(
        dataModel.map((item) => MapEntry(item['name'], item['code'])),
      );

      preference.setString(
        preference.Preference.locationBB,
        choiceListsLevel3[location[1]]!,
      );

      var roomBalance = await dioYDFWPT
          .post(
            "https://ydfwpt.gxmu.edu.cn/Home/GetRoomBanlance",
            data: {
              "roomCode":
                  preference.getString(preference.Preference.locationBB),
              "studentNumber": studentNumber,
              "__RequestVerificationToken": requestVerificationToken,
            },
            options: Options(
              headers: {
                HttpHeaders.refererHeader: referer,
              },
            ),
          )
          .then((value) => value.data);
      electricityInfo.value.remain = roomBalance['dataModel']['balance'];
      electricityInfo.value.location = "本校区/${location[0]}/${location[1]}";
    } else {
      /// ----------------------------------------
      /// 获取武鸣校区宿舍电量
      /// ----------------------------------------
      /// 获取 access_Jwt

      var specialSignIn = await dioXFEWM
          .get(
            "http://xfewm.gxmu.edu.cn/ICBS_V2_Server/v3/XINTFLg/SpecialSignIn?p3=1&p2=d275830b64be27caa72658f4bfffded7&p1=ph",
          )
          .then((value) => value.data);
      var accessJwt = specialSignIn['Data']['access_Jwt'];

      /// 获取校区信息
      var campusInfo = await dioXFEWM
          .get(
            "http://xfewm.gxmu.edu.cn/ICBS_V2_Server/v3/XINTF/GetAreaInfo?access_Jwt=$accessJwt",
            options: Options(headers: {"authorization": "Bearer $accessJwt"}),
          )
          .then((value) => value.data);
      var areaCode = campusInfo['Data']['areaInfoList'][0]['AreaID'];

      /// 获取建筑信息
      var areaInfo = await dioXFEWM
          .get(
            "http://xfewm.gxmu.edu.cn/ICBS_V2_Server/v3/XINTF/GetArchitectureInfo?AreaID=$areaCode",
            options: Options(headers: {"authorization": "Bearer $accessJwt"}),
          )
          .then((value) => value.data);
      var dataModel = areaInfo['Data']['architectureInfoList'] as List;
      Map<String, String> architectureInfo = Map<String, String>.fromEntries(
        dataModel.map(
          (item) => MapEntry(item['ArchitectureName'], item['ArchitectureID']),
        ),
      );

      /// 获取楼层房间信息
      var roomInfo = await dioXFEWM
          .get(
            "http://xfewm.gxmu.edu.cn/ICBS_V2_Server/v3/XINTF/GetRoomInfo?ArchitectureID=${architectureInfo[location[0]]}&Floor=${location[1].toString()[0]}",
            options: Options(headers: {"authorization": "Bearer $accessJwt"}),
          )
          .then((value) => value.data);
      dataModel = roomInfo['Data']['roomInfoList'] as List;
      Map<String, String> rooms = Map<String, String>.fromEntries(
        dataModel.map((item) => MapEntry(item['RoomName'], item['RoomNo'])),
      );

      /// 获取房间电表信息
      var currentRoomInfo = await dioXFEWM
          .get(
            "http://xfewm.gxmu.edu.cn/ICBS_V2_Server/v3/XINTF/GetRoomMeterInfo?RoomID=${rooms[location[1]]}",
            options: Options(headers: {"authorization": "Bearer $accessJwt"}),
          )
          .then((value) => value.data);
      var meterId = currentRoomInfo['Data']['meterList'][0]['meterId'];
      preference.setString(
        preference.Preference.locationWM,
        meterId,
      );

      preference.setString(
        preference.Preference.locationWM,
        meterId,
      );

      /// 获取电表余额
      var meterBalance = await dioXFEWM
          .get(
            "http://xfewm.gxmu.edu.cn/ICBS_V2_Server/v3/XINTF/GetReserve?MeterID=${preference.getString(preference.Preference.locationWM)}",
            options: Options(headers: {"authorization": "Bearer $accessJwt"}),
          )
          .then((value) => value.data);

      electricityInfo.value.remain = meterBalance['Data']['remainPower'];
      electricityInfo.value.location = "武鸣校区/${location[0]}/${location[1]}";
    }
  }

  List<String> getLocation(String dorm) {
    log.info(
      "[ElectricitySession][getLocation]"
      "Dorm: $dorm",
    );
    List<String> toReturn = [];
    List<String> locationList = dorm.split("/");
    //TODO: 处理宿舍楼，样本不足只能粗略估计
    if (dorm.contains("本部")) {
      /// 处理宿舍楼
      String building = locationList[2];
      int? buildingNumber;
      if (building.contains(RegExp(r'研究生'))) {
        toReturn.add("研究生公寓楼");

        if (building.contains(RegExp(r'\d'))) {
          buildingNumber = 1;
        }
      } else if (building.contains("女")) {
        toReturn.add("女生宿舍1、2、3、4楼");

        if (building.contains('1')) {
          buildingNumber = 1;
        } else if (building.contains('2')) {
          buildingNumber = 2;
        } else if (building.contains('3')) {
          buildingNumber = 3;
        } else if (building.contains('4')) {
          buildingNumber = 4;
        }
      } else if (building.contains("国际教育")) {
        toReturn.add("国际教育学院");
      } else if (building.contains("食")) {
        toReturn.add("15号楼（食堂）");
      } else if (building.contains("宿舍") ||
          building.contains(RegExp(r'([A-F])'))) {
        // 处理 A-F 楼
        if (building.contains("D")) {
          toReturn.add("宿舍D楼");
        } else if (building.contains("A") || building.contains("C")) {
          toReturn.add("宿舍A、C楼");
          buildingNumber = building.contains("A") ? 1 : 2;
        } else if (building.contains("B") || building.contains("E")) {
          toReturn.add("宿舍B、E楼");
          buildingNumber = building.contains("B") ? 1 : 2;
        }
      } else if (building.contains(RegExp(r'研.*\d'))) {
        if (building.contains(RegExp(r'[1267]'))) {
          toReturn.add("6、7号楼（研1、2#楼）");
          buildingNumber =
              building.contains("6") || building.contains("1") ? 1 : 2;
        } else if (building.contains(RegExp(r'[38]'))) {
          toReturn.add("8号楼（研3#楼）");
        } else if (building.contains(RegExp(r'(9|10|4)'))) {
          toReturn.add("9、10号楼（研4#楼）");
          buildingNumber = building.contains("9") ? 1 : 2;
        }
      } else if (building.contains("留") || building.contains(RegExp(r'(12)'))) {
        toReturn.add("12号楼（留3#楼）");
      } else if (building.contains(RegExp(r'(11|13|体)'))) {
        toReturn.add("11,13号,体育楼");
        if (building.contains(RegExp(r'11'))) {
          buildingNumber = 1;
        } else if (building.contains(RegExp(r'13'))) {
          buildingNumber = 2;
        } else if (building.contains(RegExp(r'体'))) {
          buildingNumber = 3;
        }
      } else if (building.contains(RegExp(r'(14|成)'))) {
        toReturn.add("14号楼（成1#楼）");
        if (building.contains(RegExp(r'14'))) {
          buildingNumber = 1;
        }
      } else {
        throw NotFoundException();
      }

      /// 处理房间号
      final regex = RegExp(r'(\d+)(?=[房室])');
      var room =
          "${buildingNumber ?? ""}${regex.firstMatch(locationList[4])?.group(1) ?? ""}";
      toReturn.add(room);
    } else {
      var index = locationList.indexWhere((element) => element.contains("武鸣"));
      var building = locationList[index + 1];
      if (building.contains("东")) {
        if (building.contains("1")) {
          toReturn.add("东1栋");
        } else if (building.contains("2")) {
          toReturn.add("东2栋");
        } else if (building.contains("3")) {
          toReturn.add("东3栋");
        } else if (building.contains("4")) {
          toReturn.add("东4栋");
        } else if (building.contains("5")) {
          toReturn.add("东5栋");
        } else if (building.contains("6")) {
          toReturn.add("东6栋");
        } else if (building.contains("7")) {
          toReturn.add("东7栋");
        } else {
          throw NotFoundException();
        }
      } else if (building.contains("西")) {
        if (building.contains("1")) {
          toReturn.add("西1栋");
        } else if (building.contains("2")) {
          toReturn.add("西2栋");
        } else if (building.contains("3")) {
          toReturn.add("西3栋");
        } else if (building.contains("4")) {
          toReturn.add("西4栋");
        } else if (building.contains("5")) {
          toReturn.add("西5栋");
        } else if (building.contains("6")) {
          toReturn.add("西6栋");
        } else if (building.contains("7")) {
          toReturn.add("西7栋");
        } else {
          throw NotFoundException();
        }
      } else {
        throw NotFoundException();
      }

      /// 处理房间号
      index = locationList.indexWhere(
        (element) => element.contains(RegExp(r'\d{3,}')),
      );
      final regex = RegExp(r'(\d+)(?=[房室])');
      var room = regex.firstMatch(locationList[index])?.group(1) ?? "";
      toReturn.add(room);
    }
    if (toReturn.isEmpty || toReturn.length != 2) {
      throw NotFoundException();
    }
    return toReturn;
  }

  /// 智慧公寓 appId: ddec7a102aa74d13b181154e6dee1ed1
  /// 获取宿舍位置
  @override
  Future<void> initSession() async {
    log.info(
      "[ElectricitySession][initSession]"
      "Current dorm: ${preference.getString(preference.Preference.dorm)}",
    );
    if (preference.getString(preference.Preference.dorm).isNotEmpty) {
      return;
    }

    try {
      isInit.value = SessionState.fetching;
      log.info(
        "[ElectricitySession][initSession]"
        "Fetching...",
      );

      var referer = await useApp("ddec7a102aa74d13b181154e6dee1ed1");
      var requestVerificationToken = referer.$1.split("=")[1];

      var userInfo = await dioZHGY
          .post(
            "https://gyglxt.gxmu.edu.cn/Api/Comm/Login/GetMobileLoginUserInfo",
            options: Options(
              headers: {
                "Authorization": "Bearer $requestVerificationToken",
              },
            ),
          )
          .then((value) => value.data);

      var userId = userInfo["Data"]["Id"];
      log.info(
        "[ElectricitySession][initSession]"
        "User ID: $userId",
      );

      var apartmentInfo = await dioZHGY
          .post(
            "https://gyglxt.gxmu.edu.cn/Api/Xsgy/User/QueryUserLiveInfo",
            data: {
              "userId": userId,
            },
            options: Options(
              headers: {
                "Authorization": "Bearer $requestVerificationToken",
              },
            ),
          )
          .then((value) => value.data);

      var apartmentLocation = apartmentInfo["Data"][0]["BedFullPath"];

      log.info(
        "[ElectricitySession][initSession]"
        "Apartment Location: $apartmentLocation",
      );

      preference.setString(
        preference.Preference.dorm,
        apartmentLocation,
      );
    } catch (e, s) {
      log.error(
        "[ElectricitySession][initSession]"
        "Failed to fetch electricity info: "
        "$e"
        "$s",
      );
    }
  }
}

class NotFoundException implements Exception {}

class NeedInfoException implements Exception {}

class NotInitalizedException implements Exception {
  final String msg;
  const NotInitalizedException(this.msg);
}

class NoAccountInfoException implements Exception {}

class CaptchaFailedException implements Exception {}
