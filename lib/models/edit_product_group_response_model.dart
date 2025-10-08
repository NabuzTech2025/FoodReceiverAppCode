class EditProductGroupResponseModel {
  int? id;
  int? productId;
  int? toppingGroupId;

  EditProductGroupResponseModel({this.id, this.productId, this.toppingGroupId});

  EditProductGroupResponseModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    productId = json['product_id'];
    toppingGroupId = json['topping_group_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['product_id'] = this.productId;
    data['topping_group_id'] = this.toppingGroupId;
    return data;
  }
}