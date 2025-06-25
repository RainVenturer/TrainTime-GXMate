part of 'encourage_word.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************


EncourageWord _$EncourageWordFromJson(Map<String, dynamic> json) =>
    EncourageWord(
      words: (json['words'] as List<dynamic>).map((e) => e as String).toList(),
    );



Map<String, dynamic> _$EncourageWordToJson(EncourageWord instance) =>
    <String, dynamic>{
      'words': instance.words,
    };



