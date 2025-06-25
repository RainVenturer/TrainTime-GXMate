// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0

// Copied from https://github.com/SimformSolutionsPvtLtd/flutter_calendar_view/blob/master/lib/src/event_arrangers/event_arrangers.dart.
// Removed left/right, only use stack.

import 'package:flutter/material.dart';
import 'package:watermeter/model/gxmu_ids/classtable.dart';

class ClassOrgainzedData {
  final List<dynamic> data;

  /// The time range of each block is not even in exam
  /// or experiment, so use double...
  ///
  /// Classtable blanks below per blocks.
  ///  * Morning 1-5 each 4 blocks.
  ///  * Noon break 3 blocks
  ///  * Afternoon 6-9 each 4 blocks.
  ///  * Supper time 3 blocks.
  ///  * Evening time 10-12 each 4 blocks.
  /// Total 52 parts, 49 as phone divider.
  ///
  late final double start;
  late final double stop;

  final String name;
  final Map<String, String>? place;

  final MaterialColor color;

  factory ClassOrgainzedData.fromTimeArrangement(
    TimeArrangement timeArrangement,
    MaterialColor color,
    String name,
  ) {
    double transferIndex(int index, {bool isStart = false}) {
      late double toReturn;
      if (index <= 5) {
        toReturn = index * 3.8;
        if (isStart && index == 5) {
          toReturn += 3;
        }
      } else if (index <= 9) {
        toReturn = index * 3.8 + 3;
        if (isStart && index == 9) {
          toReturn += 3;
        }
      } else {
        return index * 3.8 + 6;
      }
      return toReturn;
    }

    return ClassOrgainzedData(
      data: [timeArrangement],
      start: transferIndex(timeArrangement.start - 1, isStart: true),
      stop: transferIndex(timeArrangement.stop),
      color: color,
      name: name,
      place: timeArrangement.classroom,
    );
  }

  ClassOrgainzedData({
    required this.data,
    required this.start,
    required this.stop,
    required this.name,
    required this.color,
    this.place,
  });
}
