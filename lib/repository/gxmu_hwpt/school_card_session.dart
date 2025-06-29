// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

// Get your school card money's info, unless you use wechat or alipay...

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:qr/qr.dart';
import 'package:image/image.dart' as img;
import 'package:html/parser.dart';
import 'package:dio/dio.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:get/get.dart';
import 'package:watermeter/model/gxmu_ids/paid_record.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/gxmu_hwpt/aes_session.dart';
import 'package:watermeter/repository/gxmu_hwpt/hwpt_session.dart';
import 'package:watermeter/repository/gxmu_hwpt/hwpt_provider.dart';

Rx<SessionState> isInit = SessionState.none.obs;
RxString money = "".obs;
RxString errorSession = "".obs;

enum SignType {
  cardInfo,
  qrCode,
}

class SchoolCardSession extends HWPTSession {
  static Crypto crypto = Crypto();
  static bool firstPaidState = true;
  static String token = "";

  static String getSign(SignType type) {
    switch (type) {
      case SignType.cardInfo:
        {
          Map<String, dynamic> params = {
            "InterfaceIdentityId": HwptProvider().userData.identityId,
            "InterfaceIdentityIdType": 2,
            "CampusId": HwptProvider().userData.campusId,
            "StudentNumber": HwptProvider().userData.studentNumber,
            "Sign": "0",
            "Token": token,
          };
          return crypto.md5(jsonEncode(params));
        }
      case SignType.qrCode:
        {
          Map<String, dynamic> params = {
            "WalletType": 0,
            "WalletTypeCode": "###",
            "InterfaceIdentityId": HwptProvider().userData.identityId,
            "InterfaceIdentityIdType": 2,
            "CampusId": HwptProvider().userData.campusId,
            "StudentNumber": HwptProvider().userData.studentNumber,
            "Sign": "0",
            "Token": token,
          };
          return crypto.md5(jsonEncode(params));
        }
    }
  }

  Future<String> _getToken() async {
    // Get UTC
    var utcData = await dioHWPT.get(
      "https://hwpt.gxmu.edu.cn/tyapi/TokenAPI/GetUTC",
    );

    // Prepare for GetToken
    Map<String, dynamic> withUTC = {
      "Password": "hsKNg+At3/+YcX555jftyQ==",
      "Account": HwptProvider().userData.account,
      "UTC": utcData.data,
      "Sign": "0",
      "Token": "0",
    };
    var signForToken = crypto.md5(jsonEncode(withUTC));
    log.info("[SchoolCardSession][_getToken] signForToken: $signForToken");
    withUTC["Sign"] = signForToken;
    // Get Token
    var tokenResp = await dioHWPT
        .post(
          "https://hwpt.gxmu.edu.cn/tyapi/TokenAPI/GetToken",
          data: withUTC,
        )
        .then((value) => value.data);
    var tokenData = crypto.decrypt(tokenResp["dataModel"]);
    log.info("[SchoolCardSession][_getToken] tokenData: $tokenData");
    token = tokenData;
    return tokenData;
  }

  Future<Uint8List> getQRCode() async {
    log.info(
      "[SchoolCardSession][getQRCode] "
      "Try to get QR Code",
    );
    Map<String, dynamic> params = {
      "WalletType": 0,
      "WalletTypeCode": "###",
      "InterfaceIdentityId": HwptProvider().userData.identityId,
      "InterfaceIdentityIdType": 2,
      "CampusId": HwptProvider().userData.campusId,
      "StudentNumber": HwptProvider().userData.studentNumber,
      "Sign": getSign(SignType.qrCode),
      "Token": token,
    };
    final qrCodeUrl =
        "https://hwpt.gxmu.edu.cn/tyapi/CreateQRcodeApi/QRcodeAppointType";
    var qrCodeResp =
        await dioHWPT.post(qrCodeUrl, data: params).then((value) => value.data);

    if (qrCodeResp["isSuccess"] == false) {
      await _getToken();
      params["Sign"] = getSign(SignType.qrCode);
      params["Token"] = token;
      qrCodeResp = await dioHWPT
          .post(qrCodeUrl, data: params)
          .then((value) => value.data);
    }

    String qrCodeData = json.decode(crypto.decrypt(qrCodeResp["dataModel"]))["QRcode"];

    log.info(
      "[SchoolCardSession][getQRCode]"
      "qrCodeData: $qrCodeData",
    );

    final qrCode = QrCode.fromData(
        data: qrCodeData, errorCorrectLevel: QrErrorCorrectLevel.H);

    final qrImage = QrImage(qrCode);

    // 创建图片
    final image = img.Image(
      width: qrImage.moduleCount,
      height: qrImage.moduleCount,
    );

    // 填充二维码数据
    for (var x = 0; x < qrImage.moduleCount; x++) {
      for (var y = 0; y < qrImage.moduleCount; y++) {
        if (qrImage.isDark(y, x)) {
          image.setPixel(x, y, img.ColorRgb8(0, 0, 0)); // 黑色
        } else {
          image.setPixel(x, y, img.ColorRgb8(255, 255, 255)); // 白色
        }
      }
    }

    final resizedImage = img.copyResize(image, width: 225, height: 225);

    return img.encodePng(resizedImage);
  }

  // 获取支付记录 appid: dd854656a8f3490e9ef5186b5947e6dc
  Future<List<PaidRecord>> getPaidStatus(String begin, String end) async {
    if (isInit.value == SessionState.error ||
        isInit.value == SessionState.none) {
      await initSession();
    }
    try {
      List<PaidRecord> toReturn = [];
      var linkUrl = "";

      // Only get token once
      if (firstPaidState) {
        var linkUrl = await useApp("dd854656a8f3490e9ef5186b5947e6dc");
        await dioHWPT.get(
          linkUrl,
          options: Options(
            headers: {
              HttpHeaders.hostHeader: "zxfwq.gxmu.edu.cn",
            },
          ),
        );
        firstPaidState = false;
      }

      // Get Request Verification Token
      var cookie = await cookieJar
          .loadForRequest(Uri.parse("https://zxfwq.gxmu.edu.cn/"));
      var requestVerificationToken = "";
      for (var i in cookie) {
        if (i.name == ".AspNetCore.Antiforgery.7hHhJnQKomo") {
          requestVerificationToken = i.value;
        }
      }

      final response = await dioHWPT.post(
        "https://zxfwq.gxmu.edu.cn/QueryFlow/QueryFlowIndex",
        data: {
          "StudentNumber": HwptProvider().userData.studentNumber,
          "MinMoney": "",
          "MaxMoney": "",
          "StartTime": begin,
          "EndTime": end,
          // ignore: equal_keys_in_map
          "StudentNumber": HwptProvider().userData.studentNumber,
          "__RequestVerificationToken": requestVerificationToken,
          "Recharge": false,
          "Consumption": false,
          "Subsidy": false,
        },
        options: Options(
          headers: {
            HttpHeaders.hostHeader: "zxfwq.gxmu.edu.cn",
            HttpHeaders.refererHeader: linkUrl,
            HttpHeaders.contentTypeHeader: "application/x-www-form-urlencoded",
          },
        ),
      );
      var paidhtml = parse(response.data);
      // Find all transaction divs
      var transactionDivs = paidhtml.querySelectorAll('.info_type');

      for (var div in transactionDivs) {
        // Get the merchant name (text before the money div)
        var merchantText = div.text.split('\n')[1].replaceAll(' ', '');
        // print(merchantText);

        // Get the amount
        var moneyDiv = div.querySelector(
          '.info_money_consumption, .info_money_recharge',
        );
        if (moneyDiv == null) continue;

        var amount = moneyDiv.text.trim().replaceAll(' ', '');

        // Get the time from the next sibling div with class 'info_time'
        var timeDiv = div.parent?.querySelector('.info_time');
        var time = timeDiv?.text.trim() ?? '';

        // Create transaction object
        toReturn.add(PaidRecord(
          place: merchantText,
          money: amount,
          date: time,
        ));
      }

      log.info(
        "[SchoolCardSession][getPaidStatus]"
        "toReturn: ${toReturn.length}",
      );

      return toReturn;
    } catch (e) {
      log.error("[SchoolCardSession][getPaidStatus] $e");
      return [];
    }
  }

  @override
  Future<void> initSession() async {
    log.info(
      "[SchoolCardSession][initSession] "
      "Current State: ${isInit.value}",
    );
    if (isInit.value == SessionState.fetching) {
      return;
    }
    try {
      isInit.value = SessionState.fetching;
      log.info(
        "[SchoolCardSession][initSession] "
        "Fetching...",
      );
      await useHwpt();

      // Get Token
      await _getToken();

      // Prepare for Get Card Info
      Map<String, dynamic> params = {
        "InterfaceIdentityId": HwptProvider().userData.identityId,
        "InterfaceIdentityIdType": 2,
        "CampusId": HwptProvider().userData.campusId,
        "StudentNumber": HwptProvider().userData.studentNumber,
        "Sign": getSign(SignType.cardInfo),
        "Token": token,
      };

      // Get Card Info
      var cardInfoResp = await dioHWPT
          .post(
            "https://hwpt.gxmu.edu.cn/tyapi/UserCardInfoApi/GetUserCardInfo",
            data: params,
          )
          .then((value) => value.data);
      var cardInfoData = crypto.decrypt(cardInfoResp["dataModel"]);

      log.info(
        "[SchoolCardSession][initSession]"
        "cardInfoData: $cardInfoData",
      );

      double balance = json.decode(cardInfoData)[0]["Balance"] / 100.00;
      money.value = balance.toStringAsFixed(2);
      log.info(
        "[SchoolCardSession][initSession]"
        "Money $money",
      );

      isInit.value = SessionState.fetched;
    } catch (e, s) {
      log.error(
        "[SchoolCardSession][initSession] Money failed to fetch.",
        e,
        s,
      );
      errorSession.value = e.toString();
      money.value = "school_card_status.failed_to_fetch";
      isInit.value = SessionState.error;
    }
  }
}
