class StoreSetting {
  bool? auto_accept_orders_remote;
  bool? auto_print_orders_remote;
  bool? auto_accept_orders_local;
  bool? auto_print_orders_local;
  int? id;
  int? store_id;
  String? msg;
  int? code;
  String? mess;

  StoreSetting({
    this.auto_accept_orders_remote,
    this.auto_print_orders_remote,
    this.auto_accept_orders_local,
    this.auto_print_orders_local,
    this.id,
    this.store_id,
    this.msg,
    this.code,
    this.mess,
  });

  StoreSetting.withError({
    int? code,
    String? mess,
  })  : this.code = code,
        this.mess = mess;

  factory StoreSetting.fromJson(Map<String, dynamic> json) => StoreSetting(
        auto_accept_orders_remote: json["auto_accept_orders_remote"],
        auto_print_orders_remote: json["auto_print_orders_remote"],
        auto_accept_orders_local: json["auto_accept_orders_local"],
        auto_print_orders_local: json["auto_print_orders_local"],
        id: json["id"],
        store_id: json["store_id"],
        msg: json["msg"],
      );

  Map<String, dynamic> toJson() => {
        "auto_accept_orders_remote": auto_accept_orders_remote,
        "auto_print_orders_remote": auto_print_orders_remote,
        "auto_accept_orders_local": auto_accept_orders_local,
        "auto_print_orders_local": auto_print_orders_local,
        "id": id,
        "store_id": store_id,
        "msg": msg,
      };
}
