class GetProductGroupResponseModel {
  int? productId;
  int? toppingGroupId;
  int? id;
  Product? product;
  Group? group;

  GetProductGroupResponseModel(
      {this.productId, this.toppingGroupId, this.id, this.product, this.group});

  GetProductGroupResponseModel.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    toppingGroupId = json['topping_group_id'];
    id = json['id'];
    product =
    json['product'] != null ? new Product.fromJson(json['product']) : null;
    group = json['group'] != null ? new Group.fromJson(json['group']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['product_id'] = this.productId;
    data['topping_group_id'] = this.toppingGroupId;
    data['id'] = this.id;
    if (this.product != null) {
      data['product'] = this.product!.toJson();
    }
    if (this.group != null) {
      data['group'] = this.group!.toJson();
    }
    return data;
  }
}

class Product {
  String? name;
  String? itemCode;
  int? categoryId;
  String? imageUrl;
  String? type;
  double? price;
  int? storeId;
  int? taxId;
  bool? isActive;
  String? description;
  int? displayOrder;
  int? id;
  int? ownerId;
  Category? category;
  Tax? tax;

  Product(
      {this.name,
        this.itemCode,
        this.categoryId,
        this.imageUrl,
        this.type,
        this.price,
        this.storeId,
        this.taxId,
        this.isActive,
        this.description,
        this.displayOrder,
        this.id,
        this.ownerId,
        this.category,
        this.tax,
        });

  Product.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    itemCode = json['item_code'];
    categoryId = json['category_id'];
    imageUrl = json['image_url'];
    type = json['type'];
    price = json['price'];
    storeId = json['store_id'];
    taxId = json['tax_id'];
    isActive = json['isActive'];
    description = json['description'];
    displayOrder = json['display_order'];
    id = json['id'];
    ownerId = json['owner_id'];
    category = json['category'] != null
        ? new Category.fromJson(json['category'])
        : null;

    tax = json['tax'] != null ? new Tax.fromJson(json['tax']) : null;

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['item_code'] = this.itemCode;
    data['category_id'] = this.categoryId;
    data['image_url'] = this.imageUrl;
    data['type'] = this.type;
    data['price'] = this.price;
    data['store_id'] = this.storeId;
    data['tax_id'] = this.taxId;
    data['isActive'] = this.isActive;
    data['description'] = this.description;
    data['display_order'] = this.displayOrder;
    data['id'] = this.id;
    data['owner_id'] = this.ownerId;
    if (this.category != null) {
      data['category'] = this.category!.toJson();
    }

    if (this.tax != null) {
      data['tax'] = this.tax!.toJson();
    }
    return data;
  }
}

class Category {
  String? name;
  int? storeId;
  int? taxId;
  String? imageUrl;
  bool? isActive;
  String? description;
  int? displayOrder;
  int? id;
  Tax? tax;


  Category(
      {this.name,
        this.storeId,
        this.taxId,
        this.imageUrl,
        this.isActive,
        this.description,
        this.displayOrder,
        this.id,
        this.tax,
       });

  Category.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    storeId = json['store_id'];
    taxId = json['tax_id'];
    imageUrl = json['image_url'];
    isActive = json['isActive'];
    description = json['description'];
    displayOrder = json['display_order'];
    id = json['id'];
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
  double? percentage;
  int? storeId;
  int? id;

  Tax({this.name, this.percentage, this.storeId, this.id});

  Tax.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    percentage = json['percentage'];
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