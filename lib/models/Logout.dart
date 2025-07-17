class Logout {
  String? msg;
  int? code;
  String? mess;

  Logout({
    this.msg,
    this.code,
    this.mess,
  });

  Logout.withError({
    int? code,
    String? mess,
  })  : this.code = code,
        this.mess = mess;

  factory Logout.fromJson(Map<String, dynamic> json) => Logout(
        msg: json["msg"],
      );

  Map<String, dynamic> toJson() => {
        "msg": msg,
      };
}
