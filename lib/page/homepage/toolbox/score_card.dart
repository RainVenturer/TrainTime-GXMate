// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/page/public_widget/toast.dart';
import 'package:watermeter/page/public_widget/context_extension.dart';
import 'package:watermeter/page/score/score.dart';
import 'package:watermeter/repository/gxmu_ids/score_session.dart';
import 'package:watermeter/repository/gxmu_ids/jws_session.dart';
import 'package:watermeter/page/homepage/small_function_card.dart';

class ScoreCard extends StatelessWidget {
  const ScoreCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SmallFunctionCard(
      onTap: () {
        if (offline && !ScoreSession.isCacheExist) {
          showToast(
            context: context,
            msg: FlutterI18n.translate(
              context,
              "homepage.toolbox.score_cannot_reach",
            ),
          );
        } else {
          context.pushReplacement(const ScoreWindow());
        }
      },
      icon: Icons.grading_rounded,
      nameKey: "homepage.toolbox.score",
    );
  }
}
