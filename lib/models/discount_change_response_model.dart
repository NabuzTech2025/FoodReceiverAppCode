class ChangeDiscountPercentageResponseModel {
  String? code;
  String? type;
  double? value; // Changed from int? to double?
  String? expiresAt;
  int? storeId;
  int? id;

  ChangeDiscountPercentageResponseModel(
      {this.code,
        this.type,
        this.value,
        this.expiresAt,
        this.storeId,
        this.id});

  ChangeDiscountPercentageResponseModel.fromJson(Map<String, dynamic> json) {
    code = json['code'];
    type = json['type'];
    // Handle both int and double values for 'value' field
    if (json['value'] != null) {
      value = (json['value'] as num).toDouble();
    }
    expiresAt = json['expires_at'];
    // Handle both int and double values for 'store_id' field
    if (json['store_id'] != null) {
      storeId = (json['store_id'] as num).toInt();
    }
    // Handle both int and double values for 'id' field
    if (json['id'] != null) {
      id = (json['id'] as num).toInt();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = this.code;
    data['type'] = this.type;
    data['value'] = this.value;
    data['expires_at'] = this.expiresAt;
    data['store_id'] = this.storeId;
    data['id'] = this.id;
    return data;
  }

  // Helper method to get value as int for display purposes
  int get valueAsInt => value?.toInt() ?? 0;

  // Helper method to get value as string for text controllers
  String get valueAsString => value?.toInt().toString() ?? '0';
}