// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'score.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Score _$ScoreFromJson(Map<String, dynamic> json) => Score(
      mark: (json['mark'] as num).toInt(),
      name: json['name'] as String,
      score: (json['score'] as num?)?.toDouble(),
      gradePoint: (json['gradePoint'] as num?)?.toDouble(),
      semesterCode: json['semesterCode'] as String,
      credit: (json['credit'] as num).toDouble(),
      classStatus: json['classStatus'] as String,
      classType: json['classType'] as String,
      scoreStatus: json['scoreStatus'] as String,
      scoreType: json['scoreType'] as String,
      isPassedStr: json['isPassedStr'] as String?,
      scoreCode: json['scoreCode'] as int?,
      level: json['level'] as String?,
      isMax: json['isMax'] as bool?,
      isLevel: json['isLevel'] as bool?,
    );

Map<String, dynamic> _$ScoreToJson(Score instance) => <String, dynamic>{
      'mark': instance.mark,
      'name': instance.name,
      'score': instance.score,
      'gradePoint': instance.gradePoint,
      'semesterCode': instance.semesterCode,
      'credit': instance.credit,
      'classStatus': instance.classStatus,
      'classType': instance.classType,
      'scoreStatus': instance.scoreStatus,
      'scoreType': instance.scoreType,
      'isPassedStr': instance.isPassedStr,
      'scoreCode': instance.scoreCode,
      'level': instance.level,
      'isMax': instance.isMax,
      'isLevel': instance.isLevel,
    };

