// Copyright 2023-2025 BenderBlog Rodriguez and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0

enum ScoreFetchState {
  ok,
  error,
  fetching,
}

const double cardWidth = 280;

enum ChoiceState {
  /// All stuff from the index array.
  all,

  /// None stuff from the index array.
  none,

  /// Original stuff from the index array.
  original,
}

final courseIgnore = [
  '军事',
  '形势与政策',
  '创业基础',
  '新生',
  '写作与沟通',
  '学科导论',
  '心理',
  '物理实验',
  "安全教育",
];

final typesIgnore = [
  '通识教育选修课',
  '集中实践环节',
  '拓展提高',
  '通识教育核心课',
  '专业选修课',
];

const notCoreClassType = "公共任选";

const List<String> kScoreRanges = [
  '60分以下',
  '60-70分',
  '70-80分',
  '80-90分',
  '90分以上'
];

const List<String> kScoreLabels = ['<60', '60-70', '70-80', '80-90', '>90'];
