class getAddedtaxResponseModel {
  String? name;
  double? percentage; // Changed from int? to double?
  int? storeId;
  int? id;

  getAddedtaxResponseModel({this.name, this.percentage, this.storeId, this.id});

  getAddedtaxResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    percentage = json['percentage']?.toDouble(); // Safely convert to double
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