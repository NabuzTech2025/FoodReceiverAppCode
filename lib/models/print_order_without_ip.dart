class printOrderWithoutIp {
  String? detail;
  int? orderId;

  printOrderWithoutIp({this.detail, this.orderId});

  printOrderWithoutIp.fromJson(Map<String, dynamic> json) {
    detail = json['detail'];
    orderId = json['order_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['detail'] = this.detail;
    data['order_id'] = this.orderId;
    return data;
  }
}