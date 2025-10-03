class AddNewProductResponseModel {
  String? name;
  String? itemCode;
  int? categoryId;
  String? imageUrl;
  String? type;
  int? price;
  int? storeId;
  int? taxId;
  bool? isActive;
  String? description;
  int? displayOrder;
  int? id;
  int? ownerId;
  Category? category;
  List<Variants>? variants;
  Tax? tax;


  AddNewProductResponseModel(
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
        this.variants,
        this.tax,
        });

  AddNewProductResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    itemCode = json['item_code'];
    categoryId = json['category_id'];
    imageUrl = json['image_url'];
    type = json['type'];
    price = json['price']?.toInt();
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
    if (json['variants'] != null) {
      variants = <Variants>[];
      json['variants'].forEach((v) {
        variants!.add(new Variants.fromJson(v));
      });
    }
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
    if (this.variants != null) {
      data['variants'] = this.variants!.map((v) => v.toJson()).toList();
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
  // List<Null>? categoriesAvailability;

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
        //this.categoriesAvailability
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
    // if (json['categories_availability'] != null) {
    //   categoriesAvailability = <Null>[];
    //   json['categories_availability'].forEach((v) {
    //     categoriesAvailability!.add(new Null.fromJson(v));
    //   });
    // }
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
    // if (this.categoriesAvailability != null) {
    //   data['categories_availability'] =
    //       this.categoriesAvailability!.map((v) => v.toJson()).toList();
    // }
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

class Variants {
  String? name;
  int? price;
  String? itemCode;
  String? imageUrl;
  String? description;
  int? id;

  Variants(
      {this.name,
        this.price,
        this.itemCode,
        this.imageUrl,
        this.description,
        this.id});

  Variants.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    price = json['price']?.toInt();
    itemCode = json['item_code'];
    imageUrl = json['image_url'];
    description = json['description'];
    id = json['id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['price'] = this.price;
    data['item_code'] = this.itemCode;
    data['image_url'] = this.imageUrl;
    data['description'] = this.description;
    data['id'] = this.id;
    return data;
  }
}