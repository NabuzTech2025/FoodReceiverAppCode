class GetAllergyResponseModel {
  String? name;
  String? description;
  int? storeId;
  String? imageUrl;
  int? id;

  GetAllergyResponseModel(
      {this.name, this.description, this.storeId, this.imageUrl, this.id});

  GetAllergyResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    description = json['description'];
    storeId = json['store_id'];
    imageUrl = json['image_url'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['description'] = this.description;
    data['store_id'] = this.storeId;
    data['image_url'] = this.imageUrl;
    data['id'] = this.id;
    return data;
  }
}