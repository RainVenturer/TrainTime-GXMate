// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR  Apache-2.0

import 'package:flutter/material.dart';
import 'package:watermeter/page/classtable/arrangement_detail/arrangement_list.dart';
import 'package:watermeter/page/classtable/arrangement_detail/arrangement_detail_state.dart';
import 'package:watermeter/page/classtable/classtable_state.dart';

/// The class info of the period. This is an entry.
class ArrangementDetail extends StatelessWidget {
  final int currentWeek;
  final List<dynamic> information;
  final ClassTableWidgetState classTableState;

  const ArrangementDetail({
    super.key,
    required this.currentWeek,
    required this.information,
    required this.classTableState,
  });

  @override
  Widget build(BuildContext context) {
    return ClassTableState(
      parentContext: context,
      constraints: MediaQuery.of(context).size.width >= 600
          ? const BoxConstraints(maxWidth: 600)
          : BoxConstraints(maxWidth: MediaQuery.of(context).size.width),
      controllers: classTableState,
      child: ArrangementDetailState(
        currentWeek: currentWeek,
        information: information,
        child: const ArrangementList(),
      ),
    );
  }
}
