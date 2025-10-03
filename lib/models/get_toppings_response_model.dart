class GetToppingsResponseModel {
  String? name;
  String? description;
  int? price;
  int? storeId;
  int? id;
  bool? isActive;

  GetToppingsResponseModel(
      {this.name,
        this.description,
        this.price,
        this.storeId,
        this.id,
        this.isActive});

  GetToppingsResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    price = json['price'];
    storeId = json['store_id'];
    id = json['id'];
    isActive = json['isActive'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['description'] = this.description;
    data['price'] = this.price;
    data['store_id'] = this.storeId;
    data['id'] = this.id;
    data['isActive'] = this.isActive;
    return data;
  }
}