// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR  Apache-2.0

import 'package:flutter/material.dart';
// import 'package:watermeter/model/gxmu_ids/classtable.dart';
import 'package:watermeter/page/classtable/arrangement_detail/course_detail_card.dart';
import 'package:watermeter/page/classtable/arrangement_detail/arrangement_detail_state.dart';
import 'package:watermeter/themes/color_seed.dart';
import 'package:watermeter/page/classtable/classtable_state.dart';

/// A list of the class info in that period, in case of conflict class.
class ArrangementList extends StatelessWidget {
  const ArrangementList({super.key});

  @override
  Widget build(BuildContext context) {
    ArrangementDetailState classDetailState =
        ArrangementDetailState.of(context)!;
    return ListView(
      shrinkWrap: true,
      children: List.generate(classDetailState.information.length, (i) {
        return ClassDetailCard(
          classDetail: classDetailState.information[i].$1,
          timeArrangement: classDetailState.information[i].$2,
          infoColor: colorList[
              classDetailState.information[i].$2.index % colorList.length],
          currentWeek: classDetailState.currentWeek,
          chosenWeek: ClassTableState.of(context)!.controllers.chosenWeek,  // 获取并传入 chosenWeek
        );  
      }),
    );
  }
}
