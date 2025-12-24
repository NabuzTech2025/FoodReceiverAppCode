class GetCouponsResponseModel {
  int? storeId;
  String? code;
  String? name;
  String? couponType;
  double? value;
  double? minCartAmount;
  double? maxDiscountAmount;
  String? startAt;
  String? endAt;
  String? usageLimit;
  String? usagePerUser;
  int? id;
  bool? isActive;

  GetCouponsResponseModel(
      {this.storeId,
        this.code,
        this.name,
        this.couponType,
        this.value,
        this.minCartAmount,
        this.maxDiscountAmount,
        this.startAt,
        this.endAt,
        this.usageLimit,
        this.usagePerUser,
        this.id,
        this.isActive});

  GetCouponsResponseModel.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    code = json['code'];
    name = json['name'];
    couponType = json['coupon_type'];
    value = json['value'];
    minCartAmount = json['min_cart_amount'];
    maxDiscountAmount = json['max_discount_amount'];
    startAt = json['start_at'];
    endAt = json['end_at'];
    usageLimit = json['usage_limit'];
    usagePerUser = json['usage_per_user'];
    id = json['id'];
    isActive = json['is_active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['store_id'] = this.storeId;
    data['code'] = this.code;
    data['name'] = this.name;
    data['coupon_type'] = this.couponType;
    data['value'] = this.value;
    data['min_cart_amount'] = this.minCartAmount;
    data['max_discount_amount'] = this.maxDiscountAmount;
    data['start_at'] = this.startAt;
    data['end_at'] = this.endAt;
    data['usage_limit'] = this.usageLimit;
    data['usage_per_user'] = this.usagePerUser;
    data['id'] = this.id;
    data['is_active'] = this.isActive;
    return data;
  }
}