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
  @HiveField(6)
  int? storeType;

  UserLoginH({this.access_token, this.token_type, this.role_id , this.storeType});

  UserLoginH.withError({
    int? code,
    String? mess,
  })  : this.code = code,
        this.message = mess;

  factory UserLoginH.fromRawJson(String str) => UserLoginH.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory UserLoginH.fromJson(Map<String, dynamic> json) => UserLoginH(
        access_token: json["access_token"] == null ? null : json["access_token"],
        token_type: json["token_type"] == null ? null : json["token_type"],
        role_id: json["role_id"] == null ? null : json["role_id"],
        storeType: json["store_type"] == null ? null : json["store_type"],

      );

  Map<String, dynamic> toJson() => {
        "access_token": access_token == null ? null : access_token,
        "token_type": token_type == null ? null : token_type,
        "role_id": role_id == null ? null : role_id,
        "store_type": storeType==null ? null : storeType
      };
}
