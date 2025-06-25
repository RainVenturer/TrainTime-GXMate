// Copyright 2025 RainVenturer and contributors
// Copyright 2025 Traintime PDA authors.
// SPDX-License-Identifier: MPL-2.0 OR Apache-2.0

import 'package:json_annotation/json_annotation.dart';

part 'encourage_word.g.dart';

@JsonSerializable(explicitToJson: true)
class EncourageWord {
  List<String> words;

  EncourageWord({required this.words});

  factory EncourageWord.fromJson(Map<String, dynamic> json) =>
      _$EncourageWordFromJson(json);

  Map<String, dynamic> toJson() => _$EncourageWordToJson(this);

  @override
  int get hashCode => words.hashCode;

  @override
  bool operator ==(Object other) =>
      other is EncourageWord &&
      other.runtimeType == runtimeType &&
      words == other.words;
}
