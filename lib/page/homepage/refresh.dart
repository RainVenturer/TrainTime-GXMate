// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

// Refresh formula for homepage.

// import 'package:watermeter/controller/experiment_controller.dart';
import 'package:watermeter/model/home_arrangement.dart';
import 'package:watermeter/repository/logger.dart';
import 'package:get/get.dart';
import 'package:watermeter/controller/classtable_controller.dart';
// import 'package:watermeter/controller/exam_controller.dart';
// import 'package:watermeter/repository/gxmu_ids/school_card_session.dart'
//     as school_card_session;
import 'package:watermeter/repository/message_session.dart' as message;
// import 'package:watermeter/repository/gxmu_ids/library_session.dart'
// as borrow_info;
// import 'package:watermeter/repository/gxmu_ids/electricity_session.dart'
//     as electricity;
import 'package:watermeter/repository/gxmu_ids/jws_session.dart';
import 'package:watermeter/repository/captcha/captcha_solver.dart';
// import 'package:watermeter/repository/schoolnet_session.dart' as school_net;

DateTime updateTime = DateTime.now();

RxInt remaining = 0.obs;
RxBool isTomorrow = false.obs;
Rxn<HomeArrangement> next = Rxn<HomeArrangement>();
Rxn<HomeArrangement> current = Rxn<HomeArrangement>();
RxList<HomeArrangement> arrangement = <HomeArrangement>[].obs;
Rx<ArrangementState> arrangementState = ArrangementState.none.obs;

enum ArrangementState {
  fetching,
  fetched,
  error,
  none,
}

Future<void> _comboLogin({
  required Future<String?> Function(List<int>, DigitCaptchaType, bool)
      codeCaptcha,
}) async {
  // Guard
  if (loginState == JWSLoginState.requesting) {
    return;
  }
  loginState = JWSLoginState.requesting;

  try {
    await JWSSession().checkAndLogin(
      target: "https://jwxt.gxmu.edu.cn",
      codeCaptcha: codeCaptcha,
    );
    loginState = JWSLoginState.success;
  } on PasswordWrongException {
    loginState = JWSLoginState.passwordWrong;

    log.warning(
      "[_comboLogin] "
      "Combo login failed! Because your password is wrong.",
    );
  } catch (e, s) {
    loginState = JWSLoginState.fail;

    log.warning(
      "[_comboLogin] "
      "Combo login failed! Because of the following error: "
      "$e\nThe stack of the error is: \n$s",
    );
  }
}

Future<void> update({
  bool forceRetryLogin = false,
  required context,
  required Future<String?> Function(List<int>, DigitCaptchaType, bool)
      codeCaptcha,
}) async {
  // Update data
  message.checkMessage();

  // Retry Login
  if (forceRetryLogin || loginState == JWSLoginState.fail) {
    await _comboLogin(codeCaptcha: codeCaptcha);
  }

  await Future.wait([
    Future.wait([
      // Future(() async {
      //   final c = Get.put(ExamController());
      //   await c.get();
      // }),
      Future(() async {
        final c = Get.put(ClassTableController());
        await c.updateClassTable();
      }),
      // Future(() async {
      //   final c = Get.put(ExperimentController());
      //   await c.get();
      // }),
      // Future(() => borrow_info.LibrarySession().getBorrowList()),
      // Future(() => school_card_session.SchoolCardSession().initSession()),
      // Future(() => electricity.update()),
      // Future(() => school_net.update())
    ]).then((value) => updateCurrentData()).onError((error, stackTrace) {
      log.info(
        "[homepage Update]"
        "Update failed with following exception: $error\n"
        "$stackTrace",
      );
      updateCurrentData();
    }),
  ]);
}

/// Originally updateOnAppResumed
void updateCurrentData() {
  log.info(
    "[updateCurrentData]"
    "Updating current data. ${arrangementState.value}",
  );
  final classTableController = Get.put(ClassTableController());
  // final examController = Get.put(ExamController());
  // final experimentController = Get.put(ExperimentController());

  if (arrangementState.value == ArrangementState.fetching) {
    return;
  }
  if (classTableController.state == ClassTableState.fetching) {
    return;
  }

  arrangementState.value = ArrangementState.fetching;

  if (classTableController.state == ClassTableState.error) {
    arrangementState.value = ArrangementState.error;
    return;
  }

  // Update Classtable

  List<HomeArrangement> toAdd = [];
  updateTime = DateTime.now();

  log.info("[updateCurrentData]"
      "Update classtable, updateTime: $updateTime, "
      "isTomorrow: ${classTableController.isTomorrow(updateTime)} "
      "classTableControllerState: ${classTableController.state} "
      // "examControllerState: ${ExamStatus.fetched}",
      );
  if (classTableController.isTomorrow(updateTime)) {
    DateTime tomorrow = updateTime.add(const Duration(days: 1));
    isTomorrow.value = true;
    if (classTableController.state == ClassTableState.fetched) {
      toAdd.addAll(classTableController.getArrangementOfDay(tomorrow));
    }
    // if (examController.status == ExamStatus.fetched ||
    //     examController.status == ExamStatus.cache) {
    //   toAdd.addAll(examController.getExamOfDate(tomorrow));
    // }
    // if (experimentController.status == ExperimentStatus.fetched ||
    //     experimentController.status == ExperimentStatus.cache) {
    //   toAdd.addAll(experimentController.getExperimentOfDay(tomorrow));
    // }
  } else {
    isTomorrow.value = false;
    if (classTableController.state == ClassTableState.fetched) {
      toAdd.addAll(classTableController.getArrangementOfDay(updateTime));
    }
    // if (examController.status == ExamStatus.fetched ||
    //     examController.status == ExamStatus.cache) {
    //   toAdd.addAll(examController.getExamOfDate(updateTime));
    // }
    // if (experimentController.status == ExperimentStatus.fetched ||
    //     experimentController.status == ExperimentStatus.cache) {
    //   toAdd.addAll(experimentController.getExperimentOfDay(updateTime));
    // }
    toAdd.removeWhere((element) => !updateTime.isBefore(element.endTime));
  }

  toAdd.sort((a, b) => a.startTime.difference(b.startTime).inMicroseconds);

  arrangement.clear();
  arrangement.addAll(toAdd);
  log.info("[updateCurrentData]toAddArrangement: ${toAdd.length}");

  if (isTomorrow.isTrue) {
    current.value = null;
    next.value = arrangement.isEmpty ? null : arrangement[0];
  } else {
    Iterator<HomeArrangement> arr = arrangement.iterator;
    while (arr.moveNext()) {
      log.info(
        "[updateCurrentData] arr.current: ${arr.current.name}",
      );

      /// Is current.
      if (updateTime.microsecondsSinceEpoch >=
              arr.current.startTime.microsecondsSinceEpoch &&
          updateTime.microsecondsSinceEpoch <=
              arr.current.endTime.microsecondsSinceEpoch) {
        break;
      }

      /// If break, an hour advance.
      int inAdvance = 30;
      int currentTime = updateTime.hour * 60 + updateTime.minute;
      if (currentTime < 8.5 * 60 ||
          (currentTime < 14 * 60 && currentTime >= 12 * 60) ||
          (currentTime < 19 * 60 && currentTime >= 18 * 60)) {
        inAdvance = 60;
      }

      /// Will be occured next 30 minute.
      if (List<int>.generate(inAdvance, (index) => index)
          .contains(arr.current.startTime.difference(updateTime).inMinutes)) {
        break;
      }
    }

    try {
      current.value = arr.current;
    } on TypeError {
      current.value = null;
    }

    if (current.value == null) {
      next.value = arrangement.isEmpty ? null : arrangement[0];
    } else if (arr.moveNext()) {
      next.value = arr.current;
    } else {
      next.value = null;
    }
  }
  int len = arrangement.length;
  if (current.value != null) len -= 1;
  if (next.value != null) len -= 1;
  remaining.value = len;

  log.info(
    "[updateCurrentData]current: ${current.value?.name}, "
    "next: ${next.value?.name}, remaining: ${remaining.value}",
  );

  arrangementState.value = ArrangementState.fetched;
}
