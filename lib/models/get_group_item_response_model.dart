class GetGroupItemResponseModel {
  int? toppingGroupId;
  int? toppingId;
  int? displayOrder;
  int? id;
  Topping? topping;
  Group? group;

  GetGroupItemResponseModel(
      {this.toppingGroupId,
        this.toppingId,
        this.displayOrder,
        this.id,
        this.topping,
        this.group});

  GetGroupItemResponseModel.fromJson(Map<String, dynamic> json) {
    toppingGroupId = json['topping_group_id'];
    toppingId = json['topping_id'];
    displayOrder = json['display_order'];
    id = json['id'];
    topping =
    json['topping'] != null ? new Topping.fromJson(json['topping']) : null;
    group = json['group'] != null ? new Group.fromJson(json['group']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['topping_group_id'] = this.toppingGroupId;
    data['topping_id'] = this.toppingId;
    data['display_order'] = this.displayOrder;
    data['id'] = this.id;
    if (this.topping != null) {
      data['topping'] = this.topping!.toJson();
    }
    if (this.group != null) {
      data['group'] = this.group!.toJson();
    }
    return data;
  }
}

class Topping {
  String? name;
  String? description;
  double? price;
  int? storeId;
  int? id;
  bool? isActive;

  Topping(
      {this.name,
        this.description,
        this.price,
        this.storeId,
        this.id,
        this.isActive});

  Topping.fromJson(Map<String, dynamic> json) {
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

class Group {
  String? name;
  int? minSelect;
  int? maxSelect;
  bool? isRequired;
  int? storeId;
  int? id;
  bool? isActive;

  Group(
      {this.name,
        this.minSelect,
        this.maxSelect,
        this.isRequired,
        this.storeId,
        this.id,
        this.isActive});

  Group.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    minSelect = json['min_select'];
    maxSelect = json['max_select'];
    isRequired = json['is_required'];
    storeId = json['store_id'];
    id = json['id'];
    isActive = json['isActive'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['min_select'] = this.minSelect;
    data['max_select'] = this.maxSelect;
    data['is_required'] = this.isRequired;
    data['store_id'] = this.storeId;
    data['id'] = this.id;
    data['isActive'] = this.isActive;
    return data;
  }
}