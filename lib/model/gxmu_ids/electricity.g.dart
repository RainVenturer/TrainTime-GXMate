// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'electricity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ElectricityInfo _$ElectricityInfoFromJson(Map<String, dynamic> json) =>
    ElectricityInfo(
      fetchDay: DateTime.parse(json['fetchDay'] as String),
      remain: json['remain'] as String,
      location: json['location'] as String,
    );

Map<String, dynamic> _$ElectricityInfoToJson(ElectricityInfo instance) =>
    <String, dynamic>{
      'fetchDay': instance.fetchDay.toIso8601String(),
      'remain': instance.remain,
      'location': instance.location,
    };
