// Copyright 2023 BenderBlog Rodriguez and contributors.
// SPDX-License-Identifier: MPL-2.0

// E-hall class, which get lots of useful data here.
// Thanks xidian-script and libxdauth!

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:synchronized/synchronized.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:watermeter/repository/gxmu_ids/jws_session.dart';
import 'package:watermeter/repository/captcha/captcha_solver.dart';

class JwxtSession extends JWSSession {
  static final _ehallLock = Lock();

  /// This header shall only be used in the ehall related stuff...
  Map<String, String> refererHeader = {
    HttpHeaders.refererHeader: "https://jwxt.gxmu.edu.cn/new/desktop",
    HttpHeaders.hostHeader: "jwxt.gxmu.edu.cn",
    HttpHeaders.acceptHeader: "application/json, text/javascript, */*; q=0.01",
    HttpHeaders.acceptLanguageHeader:
        'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
    HttpHeaders.acceptEncodingHeader: 'gzip, deflate, br, zstd',
    HttpHeaders.connectionHeader: 'Keep-Alive',
    HttpHeaders.contentTypeHeader:
        "application/x-www-form-urlencoded; charset=UTF-8",
  };

  Dio get dioEhall => super.dio..options = BaseOptions(headers: refererHeader);

  Future<bool> isLoggedIn() async {
    var response = await super.dio.get(
      "https://jwxt.gxmu.edu.cn/new/welcome.page?ui=new",
    );
    log.info(
      "[ehall_session][isLoggedIn] "
      "JWXT isLoggedin: ${response.statusCode == 200}",
    );
    return response.statusCode == 200;
  }

  Future<void> loginEhall({
    required String username,
    required String password,
    required Future<String?> Function(List<int>, DigitCaptchaType, bool)
        codeCaptcha,
    required void Function(int, String) onResponse,
  }) async {
    String location = await super.login(
      target: "https://jwxt.gxmu.edu.cn",
      username: username,
      password: password,
      codeCaptcha: codeCaptcha,
      onResponse: onResponse,
    );
    var response = await dio.get(location);
    while (response.headers[HttpHeaders.locationHeader] != null) {
      location = response.headers[HttpHeaders.locationHeader]![0];
      log.info(
        "[ehall_session][loginEhall] "
        "Received location: $location",
      );
      response = await dioEhall.get(location);
    }
    return;
  }

  Future<void> useJwxt() async {
    return await _ehallLock.synchronized(() async {
      log.info(
        "[ehall_session][useJwxt] "
        "Ready to use the Jwxt. Try to Login.",
      );
      if (!await isLoggedIn()) {
        String location = await super.checkAndLogin(
          target: "https://jwxt.gxmu.edu.cn",
          codeCaptcha: (List<int> imageData, DigitCaptchaType type,
                  bool lastTry) =>
              DigitCaptchaClientProvider.solve(null, imageData, type, lastTry),
        );
        var response = await dio.get(location);
        while (response.headers[HttpHeaders.locationHeader] != null) {
          location = response.headers[HttpHeaders.locationHeader]![0];
          log.info(
            "[ehall_session][useJwxt] "
            "Received location: $location.",
          );
          response = await dioEhall.get(location);
        }
      }
      log.info(
        "[ehall_session][useJwxt] "
        "Try to use the Jwxt.",
      );
    });
  }
}

class GetInformationFailedException implements Exception {
  final String msg;
  const GetInformationFailedException(this.msg);

  @override
  String toString() => msg;
}
