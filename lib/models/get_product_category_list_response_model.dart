class GetProductCategoryList {
  String? name;
  int? storeId;
  int? taxId;
  String? imageUrl;
  bool? isActive;
  String? description;
  int? displayOrder;
  int? id;
  Tax? tax;

  GetProductCategoryList(
      {this.name,
        this.storeId,
        this.taxId,
        this.imageUrl,
        this.isActive,
        this.description,
        this.displayOrder,
        this.id,
        this.tax});

  // Update the GetProductCategoryList.fromJson method:
  GetProductCategoryList.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    storeId = json['store_id'] != null ? (json['store_id'] as num).toInt() : null;
    taxId = json['tax_id'] != null ? (json['tax_id'] as num).toInt() : null;
    imageUrl = json['image_url'];
    isActive = json['isActive'];
    description = json['description'];
    displayOrder = json['display_order'] != null ? (json['display_order'] as num).toInt() : null;
    id = json['id'] != null ? (json['id'] as num).toInt() : null;
    tax = json['tax'] != null ? new Tax.fromJson(json['tax']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['store_id'] = this.storeId;
    data['tax_id'] = this.taxId;
    data['image_url'] = this.imageUrl;
    data['isActive'] = this.isActive;
    data['description'] = this.description;
    data['display_order'] = this.displayOrder;
    data['id'] = this.id;
    if (this.tax != null) {
      data['tax'] = this.tax!.toJson();
    }
    return data;
  }
}

class Tax {
  String? name;
  int? percentage;
  int? storeId;
  int? id;

  Tax({this.name, this.percentage, this.storeId, this.id});

  Tax.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    percentage = json['percentage'] != null ? (json['percentage'] as num).toInt() : null;
    storeId = json['store_id'] != null ? (json['store_id'] as num).toInt() : null;
    id = json['id'] != null ? (json['id'] as num).toInt() : null;
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