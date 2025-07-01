part of 'hwpt.dart';

Hwpt _$HwptFromJson(Map<String, dynamic> json) => Hwpt(
      token: json['token'] as String,
      userId: json['userId'] as String,
      mechanismId: json['mechanismId'] as String,
      sitesId: json['sitesId'] as String,
      identityId: json['identityId'] as String,
      identityCode: json['identityCode'] as String,
      studentNumber: json['studentNumber'] as String,
      campusId: json['campusId'] as String,
      account: json['account'] as String,
      password: json['password'] as String,
      deskey: json['deskey'] as String,
    );

Map<String, dynamic> _$HwptToJson(Hwpt instance) => <String, dynamic>{
      'token': instance.token,
      'userId': instance.userId,
      'mechanismId': instance.mechanismId,
      'sitesId': instance.sitesId,
      'identityId': instance.identityId,
      'identityCode': instance.identityCode,
      'studentNumber': instance.studentNumber,
      'campusId': instance.campusId,
      'account': instance.account,
      'password': instance.password,
      'deskey': instance.deskey,
    };
