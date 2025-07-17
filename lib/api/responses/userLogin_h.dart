import 'dart:convert';

import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class UserLoginH extends HiveObject {
  @HiveField(0)
  String? access_token;
  @HiveField(1)
  String? token_type;
  @HiveField(3)
  int? role_id;
  @HiveField(4)
  int? code;

  @HiveField(5)
  String? message;

  UserLoginH({this.access_token, this.token_type, this.role_id});

  UserLoginH.withError({
    int? code,
    String? mess,
  })  : this.code = code,
        this.message = mess;

  //bool get isSuccess => this.success;

  /*LoginResponse.withError({
    int? code,
    bool success = false,
    String? msg,
  })  : this.statusCode = statusCode,
        this.success = success,
        this.message = msg;*/

  factory UserLoginH.fromRawJson(String str) =>
      UserLoginH.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory UserLoginH.fromJson(Map<String, dynamic> json) => UserLoginH(
        access_token:
            json["access_token"] == null ? null : json["access_token"],
        token_type: json["token_type"] == null ? null : json["token_type"],
        role_id: json["role_id"] == null ? null : json["role_id"],
        // data: UserModelH.fromJson(json["data"] == null ? null : json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "access_token": access_token == null ? null : access_token,
        "token_type": token_type == null ? null : token_type,
        "role_id": role_id == null ? null : role_id,
        // "data": data == null ? null : data,
      };
}
