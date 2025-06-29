// Copyright 2025 RainVenturer and contributors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:synchronized/synchronized.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/gxmu_hwpt/hws_session.dart';
import 'package:watermeter/repository/gxmu_hwpt/hwpt_provider.dart';

class HWPTSession extends HWSSession {
  static final _hwptLock = Lock();
  static const userDataName = "hwptUserData.json";

  /// This header shall only be used in the ehall related stuff...
  Map<String, String> refererHeader = {
    HttpHeaders.refererHeader: "https://hwpt.gxmu.edu.cn/mobile/index.html",
    HttpHeaders.hostHeader: "hwpt.gxmu.edu.cn",
    HttpHeaders.acceptHeader: "application/json, text/plain, */*",
    HttpHeaders.acceptLanguageHeader:
        'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
    HttpHeaders.acceptEncodingHeader: 'gzip, deflate, br, zstd',
    HttpHeaders.connectionHeader: 'Keep-Alive',
    HttpHeaders.contentTypeHeader:
        "application/json;charset=UTF-8",
    HttpHeaders.cookieHeader:
        "micrologistics_token=${HwptProvider().userData.token}",
    "Token": HwptProvider().userData.token,
  };

  Dio get dioHWPT => super.dio..options = BaseOptions(headers: refererHeader);

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    if (HwptProvider().state.value == HwptState.none) {
      return false;
    }
    
    try {
      var response = await dioHWPT.post(
        "https://hwpt.gxmu.edu.cn/ViewControllers/MobileView/VerifyUserToken",
        data: {},
        options: Options(
          headers: {
            HttpHeaders.refererHeader:
                "https://hwpt.gxmu.edu.cn/mobile/index.html",
            HttpHeaders.hostHeader: "hwpt.gxmu.edu.cn",
            HttpHeaders.cookieHeader:
                "micrologistics_token=${HwptProvider().userData.token}",
            "Token": HwptProvider().userData.token,
          },
        ),
      );
      return response.data['isSuccess'] == true;
    } catch (e) {
      log.warning(
        "[HWPTSession][isLoggedIn] "
        "Failed to verify login status: $e",
      );
      return false;
    }
  }

  Future<void> useHwpt() async {
    return await _hwptLock.synchronized(() async {
      log.info(
        "[hwpt_session][useHwpt] "
        "Ready to use the hwpt.",
      );
      
      final provider = HwptProvider();
      if (provider.state.value == HwptState.none) {
        await provider.initializeData();
      }

      if (!await isLoggedIn()) {
        await super.checkAndLogin(
          target: "https://hwpt.gxmu.edu.cn",
        );
      }
    });
  }

  Future<String> useApp(String appID) async {
    return await _hwptLock.synchronized(() async {
      log.info(
        "[hwpt_session][useApp] "
        "Ready to use the app $appID.",
      );

      final provider = HwptProvider();
      if (provider.state.value == HwptState.none) {
        await provider.initializeData();
      }

      if (!await isLoggedIn()) {
        await super.checkAndLogin(
          target: "https://hwpt.gxmu.edu.cn",
        );
      }

      log.info(
        "[hwpt_session][useApp] "
        "Try to use the $appID.",
      );
      var value = await dioHWPT
          .post(
            "https://hwpt.gxmu.edu.cn/ViewControllers/MobileView/GetApplicationRedirectUrl",
            data: {
              "applicationId": appID,
            },
            options: Options(
              followRedirects: false,
              validateStatus: (status) {
                return status! < 500;
              },
              headers: {
                "Token": HwptProvider().userData.token,
              },
            ),
          )
          .then((value) => value.data);
      if (value['isSuccess'] == false) {
        throw Exception(value['message']);
      }
      log.info(
        "[hwpt_session][useApp] "
        "Transfer address: ${value['dataModel']['linkUrl']}.",
      );

      return value['dataModel']['linkUrl'];
    });
  }
}
