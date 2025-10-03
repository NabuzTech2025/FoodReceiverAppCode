class AddStorePostCodesResponseModel {
  String? postcode;
  double? minimumOrderAmount;
  double? deliveryFee;
  int? deliveryTime;
  int? id;
  int? storeId;

  AddStorePostCodesResponseModel(
      {this.postcode,
        this.minimumOrderAmount,
        this.deliveryFee,
        this.deliveryTime,
        this.id,
        this.storeId});

  AddStorePostCodesResponseModel.fromJson(Map<String, dynamic> json) {
    postcode = json['postcode'];
    minimumOrderAmount = json['minimum_order_amount'];
    deliveryFee = json['delivery_fee'];
    deliveryTime = json['delivery_time'];
    id = json['id'];
    storeId = json['store_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['postcode'] = this.postcode;
    data['minimum_order_amount'] = this.minimumOrderAmount;
    data['delivery_fee'] = this.deliveryFee;
    data['delivery_time'] = this.deliveryTime;
    data['id'] = this.id;
    data['store_id'] = this.storeId;
    return data;
  }
}