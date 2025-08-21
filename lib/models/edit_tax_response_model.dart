class editTaxResponseModel {
  String? name;
  double? percentage;
  int? storeId;
  int? id;

  editTaxResponseModel({this.name, this.percentage, this.storeId, this.id});

  editTaxResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    percentage = json['percentage']?.toDouble();
    storeId = json['store_id'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['percentage'] = this.percentage;
    data['store_id'] = this.storeId;
    data['id'] = this.id;
    return data;
  }
}