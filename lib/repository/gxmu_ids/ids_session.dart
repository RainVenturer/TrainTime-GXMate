// // Copyright 2023 BenderBlog Rodriguez and contributors.
// // SPDX-License-Identifier: MPL-2.0

// // IDS (统一认证服务) login class.
// // Thanks xidian-script and libxdauth!

// import 'dart:io';
// import 'dart:convert';
// import 'package:dio/dio.dart';
// import 'package:synchronized/synchronized.dart';
// import 'package:watermeter/repository/logger.dart';
// import 'package:watermeter/repository/network_session.dart';
// import 'package:watermeter/repository/rsa_encryption.dart';
// import 'package:watermeter/repository/captcha/captcha_solver.dart';
// import 'package:watermeter/repository/preference.dart' as preference;

// enum IDSLoginState {
//   none,
//   requesting,
//   success,
//   fail,
//   passwordWrong,

//   /// Indicate that the user will login via LoginWindow
//   manual,
// }

// IDSLoginState loginState = IDSLoginState.none;

// bool get offline =>
//     loginState != IDSLoginState.success && loginState != IDSLoginState.manual;

// class IDSSession extends NetworkSession {
//   static const oAPublicExponent = "010001";
//   static const privateExponent = // private key of oa
//       "413798867d69babed22e0dd3d4031c635f3e9dbca0fa50a32974a0e230787b7f7ba78caefbee828a051c690357a8cc31dba8efc738b4db22e887571ef1ec5a5a55b6d866f6a67527f6a7d78a127c9f687008bb540228b50aa2d1ca5a4ff71107234f936b611ac46432a26da9c302eaa7180820df70593353b3f8c0247fe97a45";
//   static const oAModulus = // modulus of oa
//       "00b5eeb166e069920e80bebd1fea4829d3d1f3216f2aabe79b6c47a3c18dcee5fd22c2e7ac519cab59198ece036dcf289ea8201e2a0b9ded307f8fb704136eaeb670286f5ad44e691005ba9ea5af04ada5367cd724b5a26fdb5120cc95b6431604bd219c6b7d83a6f8f24b43918ea988a76f93c333aa5a20991493d4eb1117e7b1";
//   static const tag = "lyuap";
//   static RSAKey rsa = RSAKey(
//     oAPublicExponent,
//     privateExponent,
//     oAModulus,
//   );

//   static final _jwlock = Lock();

//   @override
//   Dio get dio => super.dio
//     ..interceptors.add(
//       InterceptorsWrapper(
//         onRequest: (options, handler) {
//           log.info(
//             "[IDSSession][OfflineCheckInspector]"
//             "Offline status: $offline",
//           );
//           if (offline) {
//             handler.reject(
//               DioException.requestCancelled(
//                 reason: "Offline mode, all ids function unuseable.",
//                 requestOptions: options,
//               ),
//             );
//           } else {
//             handler.next(options);
//           }
//         },
//       ),
//     );

//   Dio get dioNoOfflineCheck => super.dio;
//   /*
//   static const _header = [
//     // "username",
//     // "password",
//     // "service",
//     "loginType",
//     //"id",
//     //"code",
//   ];
//   */
//   Future<List> _generateIdCaptcha(String? target, String loginUserToken) async {
//     var nowTime = DateTime.now().millisecondsSinceEpoch.toString();
//     var response = await dioNoOfflineCheck.get(
//       "https://cas.gxmu.edu.cn/lyuapServer/kaptcha",
//       queryParameters: {'_t': nowTime, 'uid': ""},
//       options: Options(
//         headers: {
//           HttpHeaders.refererHeader: target != null
//               ? "https://cas.gxmu.edu.cn/lyuapServer/login$target/new/ssoLogin"
//               : "https://cas.gxmu.edu.cn/lyuapServer/login",
//           HttpHeaders.hostHeader: "cas.gxmu.edu.cn",
//           "loginUserToken": loginUserToken,
//         },
//       ),
//     );
//     var respJson = jsonDecode(response.toString());
//     String uid = respJson['uid'];
//     String captchaImageBase64 = respJson['content'].toString().split(',')[1];
//     return [uid, captchaImageBase64];
//   }

//   Future<String> _generateLoginUserToken(String? target, RSAKey rsa) async {
//     var response = await dioNoOfflineCheck.head(
//       "https://cas.gxmu.edu.cn/",
//       options: Options(
//         headers: {
//           HttpHeaders.refererHeader: target != null
//               ? "https://cas.gxmu.edu.cn/lyuapServer/login?service=$target/new/ssoLogin"
//               : "https://cas.gxmu.edu.cn/lyuapServer/login",
//         },
//       ),
//     );
//     var serverTime = response.headers['date'];
//     var dateTime = HttpDate.parse(
//       serverTime?.first ?? '',
//     ).millisecondsSinceEpoch.toString();
//     var loginTokenString = tag + dateTime;
//     String loginUserToken = RSAEncryption.encrypt(rsa, loginTokenString);
//     return loginUserToken;
//   }

//   Future<String> checkAndLogin({
//     required String target,
//     required Future<String?> Function(List<int>, DigitCaptchaType, bool)
//         codeCaptcha,
//   }) async {
//     return await _jwlock.synchronized(() async {
//       log.info(
//         "[JWSession][checkAndLogin] "
//         "Ready to get $target.",
//       );
//       var data = await dioNoOfflineCheck.get(
//         "https://jwxt.gxmu.edu.cn/new/welcome.page",
//       );
//       log.info(
//         "[IDSSession][checkAndLogin] "
//         "Received: $data.",
//       );
//       if (data.statusCode == 200) {
//         /// Post login progress, due to something wrong, return the location here...
//         return target;
//       } else {
//         return await login(
//           username: preference.getString(preference.Preference.idsAccount),
//           password: preference.getString(preference.Preference.idsPassword),
//           codeCaptcha: codeCaptcha,
//           target: target,
//         );
//       }
//     });
//   }

//   Future<String> login(
//       {required String username,
//       required String password,
//       required Future<String?> Function(List<int>, DigitCaptchaType, bool)
//           codeCaptcha,
//       bool forceReLogin = false,
//       void Function(int, String)? onResponse,
//       String? target,
//       int retryCount = 20}) async {
//     /// Get the login webpage.
//     if (onResponse != null) {
//       onResponse(10, "login_process.ready_page");
//       log.info(
//         "[IDSSession][login] "
//         "Ready to get the login webpage.",
//       );
//     }

//     var response = await dioNoOfflineCheck.get(
//       target ?? "https://cas.gxmu.edu.cn/lyuapServer/login",
//       options: Options(
//         headers: {
//           HttpHeaders.hostHeader: "cas.gxmu.edu.cn",
//           HttpHeaders.refererHeader: target,
//         },
//       ),
//     );

//     var cookieJSESSIONID = response.headers["set-cookie"]
//         ?.firstWhere((element) => element.startsWith("JSESSIONID="));

//     log.info(
//       "[IDSSession][login] "
//       "JSESSIONID: $cookieJSESSIONID.",
//     );

//     var loginUserToken = await _generateLoginUserToken(target, rsa);

//     /// Get AES encrypt key. There must be.
//     if (onResponse != null) {
//       onResponse(30, "login_process.get_encrypt");
//     }

//     Map<String, dynamic> head = {
//       'username': username,
//       'password': RSAEncryption.encrypt(rsa, password),
//       'service': target,
//       'logintype': '',
//     };

//     try {
//       for (int i = 0; i < retryCount; i++) {
//         List idCaptcha = await _generateIdCaptcha(target, loginUserToken);
//         String id = idCaptcha[0];
//         String? code = await codeCaptcha(
//           base64.decode(idCaptcha[1]).toList(), // base64 decode the image
//           DigitCaptchaType.cas,
//           i == retryCount - 1,
//         );

//         log.info(
//           "[IDSSession][login] "
//           "RetryCount:$i "
//           "id:$id, code:$code.",
//         );

//         head['id'] = id;
//         head['code'] = int.parse(code ?? '0');
//         // login
//         var data = await dioNoOfflineCheck.post(
//           "https://cas.gxmu.edu.cn/lyuapServer/v1/tickets",
//           data: head,
//           options: Options(
//             validateStatus: (status) =>
//                 status != null && status >= 200 && status < 400,
//             headers: {
//               HttpHeaders.refererHeader: target != null
//                   ? "https://cas.gxmu.edu.cn/lyuapServer/login?service=$target/new/ssoLogin"
//                   : "https://cas.gxmu.edu.cn/lyuapServer/login",
//               HttpHeaders.hostHeader: "cas.gxmu.edu.cn",
//               "loginUserToken": loginUserToken,
//             },
//           ),
//         );
//         var dataJson = jsonDecode(data.toString());

//         if (!dataJson.containsKey('tgt')) {
//           if (dataJson['data']['code'].toString().contains('CODE')) {
//             log.info(
//               "[IDSSession][login] "
//               "RetryCount:$i "
//               "Wrong code, retrying...",
//             );
//             if (onResponse != null) {
//               onResponse(35, "login_process.wrong_code");
//             }
//           } else if (dataJson['data']['code'].toString().contains('USER')) {
//             throw NoUserException(
//               msg: "User not found, please check your username.",
//             ); // NoUser
//           } else if (dataJson['data']['code'].toString().contains('PASS')) {
//             throw PasswordWrongException(
//               msg: "Password wrong, please check your password.",
//             ); // Password Wrong
//           } else {
//             throw LoginFailedException(
//               msg: "Login failed. StatusCode: ${data.statusCode}。",
//             );
//           }
//         } else {
//           log.info(
//             "[IDSSession][login] "
//             "RetryCount:$i "
//             "Successfully login.",
//           );
//           if (onResponse != null) {
//             onResponse(70, "login_process.success");
//           }

//           // redirect
//           await cookieJar.saveFromResponse(Uri.parse("https://cas.gxmu.edu.cn"),
//               [Cookie("CASTGT", dataJson["tgt"]), Cookie("session", '1')]);

//           var cookiesCas = await cookieJar
//               .loadForRequest(Uri.parse("https://cas.gxmu.edu.cn"));
//           var cookiesJwxt = await cookieJar
//               .loadForRequest(Uri.parse("https://jwxt.gxmu.edu.cn"));
//           log.info(
//             "[IDSSession][login] "
//             "Current cas cookies: $cookiesCas",
//           );
//           log.info(
//             "[IDSSession][login] "
//             "Current jwxt cookies: $cookiesJwxt",
//           );

//           Map<String, String> params = {
//             "ticket": dataJson["ticket"],
//           };
//           var redirect = await dioNoOfflineCheck.get(
//             target != null
//                 ? "$target/new/ssoLogin"
//                 : "http://portal.gxmu.edu.cn/",
//             queryParameters: params,
//             options: Options(
//               headers: {
//                 HttpHeaders.refererHeader:
//                     target != null ? "https://cas.gxmu.edu.cn/" : "",
//                 HttpHeaders.hostHeader:
//                     target?.split('//')[1] ?? "cas.gxmu.edu.cn",
//                 HttpHeaders.cookieHeader: cookieJSESSIONID ?? ""
//               },
//               validateStatus: (status) =>
//                   status != null && status >= 200 && status < 500,
//             ),
//           );
//           if (redirect.statusCode == 301 || redirect.statusCode == 302) {
//             /// Post login progress.
//             if (onResponse != null) {
//               onResponse(80, "login_process.after_process");
//             }
//             return redirect.headers[HttpHeaders.locationHeader]![0];
//           } else {
//             throw LoginFailedException(
//                 msg: "登录失败，响应状态码：${redirect.statusCode}。");
//           }
//         } // End if
//       } // End for
//       throw FailVeriCodeException(msg: "Fail to get the verification code.");
//     } on DioException {
//       rethrow;
//     }
//   }
//   /*
//   Future<bool> checkWhetherPostgraduate() async {
//     String location = await checkAndLogin(
//       target: "https://yjspt.xidian.edu.cn/gsapp"
//           "/sys/yjsemaphome/portal/index.do",
//       sliderCaptcha: (cookieStr) =>
//           SliderCaptchaClientProvider(cookie: cookieStr).solve(null),
//     );
//     var response = await dio.get(location);
//     while (response.headers[HttpHeaders.locationHeader] != null) {
//       location = response.headers[HttpHeaders.locationHeader]![0];
//       log.info(
//         "[checkWhetherPostgraduate] Received location: $location",
//       );
//       response = await dio.get(location);
//     }

//     bool toReturn = await dio
//         .post("https://yjspt.xidian.edu.cn/gsapp"
//             "/sys/yjsemaphome/modules/pubWork/getCanVisitAppList.do")
//         .then((value) => value.data["res"] != null);

//     preference.setBool(
//       preference.Preference.role,
//       toReturn,
//     );

//     return toReturn;
//   }
//   */
// }

// class PasswordWrongException implements Exception {
//   final String msg;
//   const PasswordWrongException({required this.msg});
//   @override
//   String toString() => msg;
// }

// class LoginFailedException implements Exception {
//   final String msg;
//   const LoginFailedException({required this.msg});
//   @override
//   String toString() => msg;
// }

// class NoUserException implements Exception {
//   final String msg;
//   const NoUserException({required this.msg});
//   @override
//   String toString() => msg;
// }

// class FailVeriCodeException implements Exception {
//   final String msg;
//   const FailVeriCodeException({required this.msg});
//   @override
//   String toString() => msg;
// }
