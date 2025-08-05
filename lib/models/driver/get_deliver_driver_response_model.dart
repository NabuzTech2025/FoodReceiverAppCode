class GetDeliverDriverResponseModel {
  int? userId;
  int? storeId;
  int? id;
  bool? isActive;

  GetDeliverDriverResponseModel(
      {this.userId, this.storeId, this.id, this.isActive});

  GetDeliverDriverResponseModel.fromJson(Map<String, dynamic> json) {
    userId = json['user_id'];
    storeId = json['store_id'];
    id = json['id'];
    isActive = json['is_active'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['store_id'] = this.storeId;
    data['id'] = this.id;
    data['is_active'] = this.isActive;
    return data;
  }
}