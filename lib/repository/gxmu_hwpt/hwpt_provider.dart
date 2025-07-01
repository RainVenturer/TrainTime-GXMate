// Copyright 2025 RainVenturer and contributors.
// SPDX-License-Identifier: MPL-2.0

import 'dart:io';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:watermeter/repository/gxmu_hwpt/model/hwpt.dart';
import 'package:watermeter/repository/network_session.dart';
import 'package:watermeter/repository/gxmu_hwpt/hwpt_session.dart';
import 'package:watermeter/repository/logger.dart';

enum HwptState {
  initial,    // 初始化状态
  fetching,   // 正在获取数据
  fetched,    // 数据获取完成
  error,      // 发生错误
  none,       // 未初始化
}

class HwptProvider extends GetxController {
  static final HwptProvider _instance = HwptProvider._internal();
  static const userDataName = "hwptUserData.json";
  factory HwptProvider() => _instance;
  HwptProvider._internal();

  Rx<HwptState> state = HwptState.none.obs;
  String? error;

  late File userDataFile;
  late Hwpt _userData;

  Hwpt get userData => _userData;

  @override
  void onInit() {
    super.onInit();
    log.info(
      "[HwptState][onInit] "
      "Init hwpt file.",
    );
    userDataFile = File(
      "${supportPath.path}/$userDataName",
    );
    initializeData();
  }

  Future<void> initializeData() async {
    if (state.value != HwptState.none && state.value != HwptState.initial) {
      return;
    }

    try {
      bool userDataFileIsExist = userDataFile.existsSync();
      if (userDataFileIsExist) {
        log.info(
          "[HwptState][initializeData] "
          "Init from cache.",
        );
        _userData = Hwpt.fromJson(
          jsonDecode(userDataFile.readAsStringSync()),
        );
        state.value = HwptState.initial;
      } else {
        log.info(
          "[HwptState][initializeData] "
          "Init from empty.",
        );
        _userData = Hwpt.empty();
        state.value = HwptState.none;
      }
    } catch (e, s) {
      log.warning(
        "[HwptState][initializeData] "
        "Failed to initialize data: $e\n$s",
      );
      state.value = HwptState.error;
      error = e.toString();
      _userData = Hwpt.empty();
    }
  }

  Future<void> updateUserData({bool isForce = false}) async {
    if (state.value == HwptState.fetching) return;

    state.value = HwptState.fetching;
    error = null;

    try {
      bool userDataFileIsExist = userDataFile.existsSync();
      bool isNotNeedRefreshCache = userDataFileIsExist &&
          !isForce &&
          DateTime.now().difference(userDataFile.lastModifiedSync()).inDays <=
              2;

      if (isNotNeedRefreshCache) {
        _userData = Hwpt.fromJson(
          jsonDecode(userDataFile.readAsStringSync()),
        );
      } else {
        await HWPTSession().checkAndLogin(
          target: "https://hwpt.gxmu.edu.cn",
        );
      }
      state.value = HwptState.fetched;
    } catch (e, s) {
      log.warning(
        "[HwptState][updateUserData] "
        "Failed to update data: $e\n$s",
      );
      state.value = HwptState.error;
      error = e.toString();
    }
  }

  void loadUserData(Hwpt userData) {
    _userData = userData;
    state.value = HwptState.fetched;
    saveUserData();
  }

  void saveUserData() {
    userDataFile.writeAsStringSync(
      jsonEncode(_userData.toJson()),
    );
  }
}
