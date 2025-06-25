// Copyright 2025 RainVenturer
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:watermeter/model/gxmu_ids/score.dart';
import 'package:watermeter/page/public_widget/public_widget.dart';
import 'package:watermeter/page/score/score_statics.dart';

class ScoreAnalyzeCard extends StatelessWidget {
  final List<ComposeAnalyze> analyzeData;

  const ScoreAnalyzeCard({
    super.key,
    required this.analyzeData,
  });

  /// 获取课程排名数据
  ComposeAnalyze? get courseData =>
      analyzeData.isNotEmpty ? analyzeData[0] : null;

  /// 获取班级排名数据
  ComposeAnalyze? get classData =>
      analyzeData.length > 1 ? analyzeData[1] : null;

  @override
  Widget build(BuildContext context) {
    if (analyzeData.isEmpty) {
      return _buildEmptyState(context);
    }
    // 单个排名
    if (analyzeData.length == 1) {
      return _buildSingleRankState(context);
    }
    // 存在课程排名与班级成绩分布
    return _buildFullState(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    return InfoDetailBox(
      child: Center(
        child: Text(
          FlutterI18n.translate(
            context,
            "score.score_analyze_card.no_data",
          ),
        ),
      ),
    );
  }

  Widget _buildSingleRankState(BuildContext context) {
    return InfoDetailBox(
      child: Column(
        children: [
          RankDisplay(
            translationKey: "score.score_analyze_card.class_rank",
            rank: courseData?.rank ?? 0,
            total: courseData?.total ?? 0,
          ),
        ],
      ),
    );
  }

  Widget _buildFullState(BuildContext context) {
    return InfoDetailBox(
      child: Column(
        children: [
          const SizedBox(height: 8.0),
          Text(
            FlutterI18n.translate(
              context,
              "score.score_analyze_card.distribution_title",
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16.0),
          if (classData != null)
            ScoreDistributionChart(data: classData!), // 班级成绩分布图
          const SizedBox(height: 16.0),
          if (courseData != null)
            RankDisplay(
              translationKey: "score.score_analyze_card.course_rank",
              rank: courseData!.rank,
              total: courseData!.total,
            ),
          const SizedBox(height: 8.0),
          if (classData != null)
            RankDisplay(
              translationKey: "score.score_analyze_card.class_rank",
              rank: classData!.rank,
              total: classData!.total,
            ),
        ],
      ),
    );
  }
}

class ScoreDistributionChart extends StatelessWidget {
  final ComposeAnalyze data;

  const ScoreDistributionChart({
    super.key,
    required this.data,
  });

  /// 获取最大值
  double get maxValue {
    double max = 0;
    for (var score in kScoreRanges) {
      max = [max, (data.scoreDsitribution[score] ?? 0).toDouble()]
          .reduce((max, value) => max > value ? max : value);
    }
    return ((max / 10).ceil() * 10).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200.0,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue,
          barGroups: _createBarGroups(context),
          titlesData: _createTitlesData(),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  List<BarChartGroupData> _createBarGroups(BuildContext context) {
    return List.generate(kScoreRanges.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (data.scoreDsitribution[kScoreRanges[index]] ?? 0).toDouble(),
            color: Theme.of(context).colorScheme.primary,
            width: 20.0,
          ),
        ],
      );
    });
  }

  FlTitlesData _createTitlesData() {
    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                kScoreLabels[value.toInt()],
                style: const TextStyle(fontSize: 12),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: 10,
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.right,
              ),
            );
          },
        ),
      ),
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
    );
  }
}

class RankDisplay extends StatelessWidget {
  final String translationKey;
  final int rank;
  final int total;

  const RankDisplay({
    super.key,
    required this.translationKey,
    required this.rank,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      FlutterI18n.translate(
        context,
        translationKey,
        translationParams: {
          "rank": rank.toString(),
          "total": total.toString(),
        },
      ),
    );
  }
}
