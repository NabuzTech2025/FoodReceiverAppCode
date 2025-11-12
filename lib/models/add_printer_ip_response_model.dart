class AddPrinterIpResponseModel {
  String? name;
  String? ipAddress;
  int? storeId;
  bool? isActive;
  int? type;
  int? categoryId;
  bool? isRemote;
  int? id;

  AddPrinterIpResponseModel(
      {this.name,
        this.ipAddress,
        this.storeId,
        this.isActive,
        this.type,
        this.categoryId,
        this.isRemote,
        this.id});

  AddPrinterIpResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    ipAddress = json['ip_address'];
    storeId = json['store_id'];
    isActive = json['isActive'];
    type = json['type'];
    categoryId = json['category_id'];
    isRemote = json['isRemote'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['ip_address'] = this.ipAddress;
    data['store_id'] = this.storeId;
    data['isActive'] = this.isActive;
    data['type'] = this.type;
    data['category_id'] = this.categoryId;
    data['isRemote'] = this.isRemote;
    data['id'] = this.id;
    return data;
  }
}