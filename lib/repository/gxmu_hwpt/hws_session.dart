// Copyright 2023 BenderBlog Rodriguez and contributors.
// SPDX-License-Identifier: MPL-2.0

// HWPT (后勤服务) login class.

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:synchronized/synchronized.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/preference.dart' as preference;
import 'package:watermeter/repository/gxmu_hwpt/model/hwpt.dart';
import 'package:watermeter/repository/gxmu_ids/jws_session.dart';
import 'package:watermeter/repository/gxmu_hwpt/hwpt_provider.dart';

import 'package:cookie_jar/cookie_jar.dart';

enum HWPTLoginState {
  none,
  requesting,
  success,
  fail,
  passwordWrong,

  /// Indicate that the user will login via LoginWindow
  manual,
}

HWPTLoginState loginStateHWPT = HWPTLoginState.none;

bool get offline =>
    loginStateHWPT != HWPTLoginState.success &&
    loginStateHWPT != HWPTLoginState.manual;

class HWSSession extends NetworkSession {
  static final _hwptlock = Lock();

  @override
  PersistCookieJar get cookieJar => PersistCookieJar(
        persistSession: true,
        storage: FileStorage("${supportPath.path}/cookie/hwpt"),
      );

  @override
  Dio get dio => super.dio
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          log.info(
            "[HWPT][OfflineCheckInspector]"
            "Offline status: $offline",
          );
          if (offline) {
            handler.reject(
              DioException.requestCancelled(
                reason: "Offline mode, all hwpt function unuseable.",
                requestOptions: options,
              ),
            );
          } else {
            handler.next(options);
          }
        },
      ),
    );

  Dio get dioNoOfflineCheck => super.dio
    ..options.headers = {
      HttpHeaders.acceptHeader: "application/json, text/plain, */*",
      HttpHeaders.acceptEncodingHeader: "gzip, deflate, br, zstd",
      HttpHeaders.contentTypeHeader: "application/json;charset=UTF-8",
    };

  Future<Hwpt> checkAndLogin({
    required String target,
  }) async {
    return await _hwptlock.synchronized(() async {
      log.info(
        "[HWPT][checkAndLogin] "
        "Ready to get $target.",
      );
      await dioNoOfflineCheck.get(
        "https://hwpt.gxmu.edu.cn/mobile/index.html",
        options: Options(
          headers: {
            HttpHeaders.hostHeader: "hwpt.gxmu.edu.cn",
          },
        ),
      );
      // Get index config
      var indexConfig = await dioNoOfflineCheck
          .get(
            "https://hwpt.gxmu.edu.cn/mobile/config/index.js",
            options: Options(
              headers: {
                HttpHeaders.hostHeader: "hwpt.gxmu.edu.cn",
                HttpHeaders.refererHeader:
                    "https://hwpt.gxmu.edu.cn/mobile/index.html",
              },
            ),
          )
          .then((value) => value.data);
      // Parse index config
      final dataStringList = indexConfig
          .replaceAll(RegExp(r'(?<!:)//.*'), '') // 移除单行注释，但保留URL中的 //
          .replaceAll(' ', '')
          .replaceAll(RegExp(r'\s+'), '\n') // 移除所有空白字符（包括空行）
          .replaceAll(RegExp(r'^\s*$\n', multiLine: true), '') // 移除空行
          .replaceAll('window.', '')
          .replaceAll('"', '')
          .split('\n');
      final indexConfigMap = <String, dynamic>{};
      for (var i in dataStringList) {
        final key = i.substring(0, i.indexOf('='));
        final value = i.substring(i.indexOf('=') + 1);
        indexConfigMap[key] = value;
      }
      // verify the session
      var data = await dioNoOfflineCheck
          .post(
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
          )
          .then((value) => value.data);
      log.info(
        "[HWPT][checkAndLogin] "
        "Received message: ${data['message']}.",
      );
      if (data['isSuccess'] == true) {
        Hwpt toReturn = Hwpt(
          token: data['dataModel']['token'],
          userId: data['dataModel']['userInfo']['id'],
          mechanismId: data['dataModel']['userInfo']['mechanismId'],
          sitesId: data['dataModel']['userInfo']['sitesId'],
          identityId: data['dataModel']['userInfo']['identityId'],
          studentNumber: data['dataModel']['userInfo']['studentNumber'],
          cardNumber: data['dataModel']['userInfo']['userMechanismInfos'][0]
              ['cardNumber'],
          identityCode: data['dataModel']['userInfo']['identityCode'],
          campusId: indexConfigMap['CampusId'].replaceAll('\'', ''),
          account: indexConfigMap['account'],
          password: indexConfigMap['password'],
          deskey: indexConfigMap['desKey'],
        );
        HwptProvider().loadUserData(toReturn);
        return toReturn;
      } else {
        return await login(
          username: preference.getString(preference.Preference.idsAccount),
          password: preference
                      .getString(preference.Preference.schoolCardPassword) ==
                  ""
              ? preference.getString(preference.Preference.idCardSix)
              : preference.getString(preference.Preference.schoolCardPassword),
          target: target,
        );
      }
    });
  }

  Future<Hwpt> login(
      {required String username,
      required String password,
      bool forceReLogin = false,
      String? target,
      int retryCount = 20}) async {
    /// Get the login webpage.
    log.info(
      "[HWPT][login] "
      "Ready to get the login webpage.",
    );

    await dioNoOfflineCheck.get(
      "https://hwpt.gxmu.edu.cn/mobile/index.html",
      options: Options(
        headers: {
          HttpHeaders.hostHeader: "hwpt.gxmu.edu.cn",
        },
      ),
    );

    // Get index config
    var indexConfig = await dioNoOfflineCheck
        .get(
          "https://hwpt.gxmu.edu.cn/mobile/config/index.js",
          options: Options(
            headers: {
              HttpHeaders.hostHeader: "hwpt.gxmu.edu.cn",
              HttpHeaders.refererHeader:
                  "https://hwpt.gxmu.edu.cn/mobile/index.html",
            },
          ),
        )
        .then((value) => value.data);
    // Parse index config
    final dataStringList = indexConfig
        .replaceAll(RegExp(r'(?<!:)//.*'), '') // 移除单行注释，但保留URL中的 //
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'\s+'), '\n') // 移除所有空白字符（包括空行）
        .replaceAll(RegExp(r'^\s*$\n', multiLine: true), '') // 移除空行
        .replaceAll('window.', '')
        .replaceAll('"', '')
        .split('\n');
    final indexConfigMap = <String, dynamic>{};
    for (var i in dataStringList) {
      final key = i.substring(0, i.indexOf('='));
      final value = i.substring(i.indexOf('=') + 1);
      indexConfigMap[key] = value;
    }

    var response = await dioNoOfflineCheck
        .post(
          "https://hwpt.gxmu.edu.cn/ViewControllers/MobileView/GetMechanismInfos",
          data: {},
          options: Options(
            headers: {
              HttpHeaders.hostHeader: "hwpt.gxmu.edu.cn",
              HttpHeaders.refererHeader:
                  "https://hwpt.gxmu.edu.cn/mobile/index.html",
            },
          ),
        )
        .then((value) => value.data);

    if (response['isSuccess'] == false) {
      throw LoginFailedException(
        msg: "POST failed. StatusCode: ${response['code']}.",
      );
    }

    String mechanismId = response['dataModel'][0]['id'];

    Map<String, dynamic> head = {
      'account': username,
      'password': password,
      'mechanismId': mechanismId,
      'openId': null,
    };

    try {
      log.info(
        "[HWPT][login] "
        "Ready to login.",
      );

      // login
      var data = await dioNoOfflineCheck
          .post(
            "https://hwpt.gxmu.edu.cn/ViewControllers/MobileView/UserLogin",
            data: head,
            options: Options(
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 400,
              headers: {
                HttpHeaders.refererHeader:
                    "https://hwpt.gxmu.edu.cn/mobile/index.html",
                HttpHeaders.hostHeader: "hwpt.gxmu.edu.cn",
              },
            ),
          )
          .then((value) => value.data);

      if (!data['isSuccess']) {
        var message = data['message'];
        if (message.toString().contains('无效')) {
          throw NoUserException(
            msg: "User not found, please check your username.\n$message",
          );
        } else if (message.toString().contains('错误')) {
          throw PasswordWrongException(
            msg: "Password wrong, please check your password.\n$message",
          );
        } else {
          throw LoginFailedException(
            msg: "Login failed.\ncode: ${data['code']}\nmessage: $message",
          );
        }
      }

      // 保存 cookie
      await cookieJar.saveFromResponse(
        Uri.parse("https://hwpt.gxmu.edu.cn"),
        [Cookie("micrologistics_token", data["dataModel"]["token"])],
      );

      // 获取站点信息
      var getSitesInfos = await dioNoOfflineCheck
          .post(
            "https://hwpt.gxmu.edu.cn/ViewControllers/MobileView/GetSitesInfos",
            data: {
              'mechanismId': mechanismId,
            },
            options: Options(
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 400,
              headers: {
                HttpHeaders.refererHeader:
                    "https://hwpt.gxmu.edu.cn/mobile/index.html",
                HttpHeaders.hostHeader: "hwpt.gxmu.edu.cn",
              },
            ),
          )
          .then((value) => value.data);

      // 更新用户令牌
      var updateUserToken = await dioNoOfflineCheck
          .post(
            "https://hwpt.gxmu.edu.cn/ViewControllers/MobileView/UpdateUserToken",
            data: {
              'token': data['dataModel']['token'],
              'mechanismId': mechanismId,
              'sitesId': data['dataModel']['userInfo']['sitesId'],
              'openId': null,
            },
            options: Options(
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 400,
              headers: {
                HttpHeaders.refererHeader:
                    "https://hwpt.gxmu.edu.cn/mobile/index.html",
                HttpHeaders.hostHeader: "hwpt.gxmu.edu.cn",
                HttpHeaders.cookieHeader:
                    "micrologistics_token=${data['dataModel']['token']}",
                "Token": data['dataModel']['token'],
              },
            ),
          )
          .then((value) => value.data);

      // 验证用户令牌
      var verifyUserToken = await dioNoOfflineCheck
          .post(
            "https://hwpt.gxmu.edu.cn/ViewControllers/MobileView/VerifyUserToken",
            data: {},
            options: Options(
              validateStatus: (status) =>
                  status != null && status >= 200 && status < 400,
              headers: {
                HttpHeaders.refererHeader:
                    "https://hwpt.gxmu.edu.cn/mobile/index.html",
                HttpHeaders.hostHeader: "hwpt.gxmu.edu.cn",
                HttpHeaders.cookieHeader:
                    "micrologistics_token=${data['dataModel']['token']}",
                "Token": data['dataModel']['token'],
              },
            ),
          )
          .then((value) => value.data);

      if (!getSitesInfos['isSuccess'] ||
          !updateUserToken['isSuccess'] ||
          !verifyUserToken['isSuccess']) {
        throw LoginFailedException(
            msg: "Login failed: cannot complete after operation.");
      }

      log.info(
        "[HWPT][login] "
        "Login successful",
      );
      Hwpt toReturn = Hwpt(
        token: data['dataModel']['token'],
        userId: data['dataModel']['userInfo']['id'],
        mechanismId: data['dataModel']['userInfo']['mechanismId'],
        sitesId: data['dataModel']['userInfo']['sitesId'],
        identityId: data['dataModel']['userInfo']['identityId'],
        studentNumber: data['dataModel']['userInfo']['studentNumber'],
        cardNumber: data['dataModel']['userInfo']['userMechanismInfos'][0]
            ['cardNumber'],
        identityCode: data['dataModel']['userInfo']['identityCode'],
        campusId: indexConfigMap['CampusId'].replaceAll('\'', ''),
        account: indexConfigMap['account'],
        password: indexConfigMap['password'],
        deskey: indexConfigMap['desKey'],
      );
      HwptProvider().loadUserData(toReturn);
      return toReturn;
    } on DioException {
      rethrow;
    }
  }
}

// class PasswordWrongException implements Exception {
//   final String msg;
//   const PasswordWrongException({required this.msg});
//   @override
//   String toString() => msg;
// }

class LoginFailedException implements Exception {
  final String msg;
  const LoginFailedException({required this.msg});
  @override
  String toString() => msg;
}

class NoUserException implements Exception {
  final String msg;
  const NoUserException({required this.msg});
  @override
  String toString() => msg;
}
