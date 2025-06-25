// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:styled_widget/styled_widget.dart';
import 'package:watermeter/page/public_widget/public_widget.dart';
import 'package:watermeter/page/public_widget/re_x_card.dart';
import 'package:watermeter/model/gxmu_ids/score.dart';
import 'package:watermeter/page/score/score_analyze_card.dart';

class ScoreComposeCard extends Dialog {
  final Score score;
  final Future<List<ComposeDetail>> detail;
  final Future<List<ComposeAnalyze>> analyze;
  const ScoreComposeCard({
    super.key,
    required this.score,
    required this.detail,
    required this.analyze,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([detail, analyze]),
      builder: (context, snapshot) {
        late Widget info;
        late Widget analyzeInfo;
        
        if (snapshot.hasData) {
          final detailData = snapshot.data![0] as List<ComposeDetail>;
          final analyzeData = snapshot.data![1] as List<ComposeAnalyze>;
          
          // Handle detail information
          info = _buildDetailInfo(context, detailData);
          
          // Handle analyze information
          analyzeInfo = _buildAnalyzeInfo(analyzeData);
          
        } else if (snapshot.hasError) {
          info = InfoDetailBox(
            child: Center(
              child: Text(
                FlutterI18n.translate(
                  context,
                  "score.score_compose_card.no_detail",
                ),
              ),
            ),
          );
          analyzeInfo = const SizedBox.shrink();
        } else {
          info = InfoDetailBox(
            child: Center(
              child: Text(
                FlutterI18n.translate(
                  context,
                  "score.score_compose_card.fetching",
                ),
              ),
            ),
          );
          analyzeInfo = const SizedBox.shrink();
        }
        
        return ReXCard(
          title: Text(score.name),
          remaining: [ReXCardRemaining(score.semesterCode)],
          bottomRow: [
            [
              Text(
                "${FlutterI18n.translate(
                  context,
                  "score.score_compose_card.credit",
                )}: ${score.credit}",
              ).expanded(flex: 2),
              Text(
                "${FlutterI18n.translate(
                  context,
                  "score.score_compose_card.gpa",
                )}: ${score.gpa}",
              ).expanded(flex: 3),
              Text(
                "${FlutterI18n.translate(
                  context,
                  "score.score_compose_card.score",
                )}: ${score.scoreStr}",
              ).expanded(flex: 3),
            ].toRow(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
            ),
            const SizedBox(height: 8),
            info,
            const SizedBox(height: 8),
            analyzeInfo,
          ].toColumn(crossAxisAlignment: CrossAxisAlignment.center),
        );
      },
    );
  }

  // Helper method to build detail information
  Widget _buildDetailInfo(BuildContext context, List<ComposeDetail> detailData) {
    if (detailData.isEmpty) {
      return InfoDetailBox(
        child: Center(
          child: Text(
            FlutterI18n.translate(
              context,
              "score.score_compose_card.no_detail",
            ),
          ),
        ),
      );
    }

    return InfoDetailBox(
      child: Table(
        children: List<TableRow>.generate(
          detailData.length,
          (i) => _buildScoreDetailRow(detailData[i]),
        ),
      ),
    );
  }

  // Helper method to build a single score detail row
  TableRow _buildScoreDetailRow(ComposeDetail detail) {
    return TableRow(
      children: <Widget>[
        TableCell(
          child: Text(detail.content),
        ),
        TableCell(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(detail.ratio),
          ),
        ),
        TableCell(
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(detail.score),
          ),
        ),
      ],
    );
  }

  // Helper method to build analyze information
  Widget _buildAnalyzeInfo(List<ComposeAnalyze> analyzeData) {
    if (analyzeData.isEmpty) {
      return const SizedBox.shrink();
    }
    return ScoreAnalyzeCard(analyzeData: analyzeData);
  }
}
