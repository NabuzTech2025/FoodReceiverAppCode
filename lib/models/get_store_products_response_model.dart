class GetStoreProducts {
  String? name;
  String? itemCode;
  int? categoryId;
  String? imageUrl;
  String? type;
  double? price;
  double? discountPrice;
  int? storeId;
  String? taxId;
  bool? isActive;
  String? description;
  int? displayOrder;
  int? id;
  int? ownerId;
  Category? category;
  List<Variants>? variants;
  String? tax;


  GetStoreProducts(
      {this.name,
        this.itemCode,
        this.categoryId,
        this.imageUrl,
        this.type,
        this.price,
        this.discountPrice,
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

  GetStoreProducts.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();
    itemCode = json['item_code']?.toString();
    categoryId = json['category_id'] != null ? (json['category_id'] as num).toInt() : null;
    imageUrl = json['image_url']?.toString();
    type = json['type']?.toString();
    price = json['price']?.toDouble();
    discountPrice = json['discount_price']?.toDouble();
    storeId = json['store_id'] != null ? (json['store_id'] as num).toInt() : null;
    taxId = json['tax_id']?.toString();
    isActive = json['isActive'] as bool?;  // ✅ ADDED
    description = json['description']?.toString();
    displayOrder = json['display_order'] != null ? (json['display_order'] as num).toInt() : null;
    id = json['id'] != null ? (json['id'] as num).toInt() : null;
    ownerId = json['owner_id'] != null ? (json['owner_id'] as num).toInt() : null;
    category = json['category'] != null
        ? Category.fromJson(json['category'])
        : null;
    if (json['variants'] != null) {
      variants = <Variants>[];
      json['variants'].forEach((v) {
        variants!.add(Variants.fromJson(v));
      });
    }
    tax = json['tax']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['item_code'] = itemCode;
    data['category_id'] = categoryId;
    data['image_url'] = imageUrl;
    data['type'] = type;
    data['price'] = price;
    data['discount_price'] = this.discountPrice;
    data['store_id'] = storeId;
    data['tax_id'] = taxId;
    data['isActive'] = isActive;
    data['description'] = description;
    data['display_order'] = displayOrder;
    data['id'] = id;
    data['owner_id'] = ownerId;
    if (category != null) {
      data['category'] = category!.toJson();
    }
    if (variants != null) {
      data['variants'] = variants!.map((v) => v.toJson()).toList();
    }
    data['tax'] = tax;
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
    name = json['name']?.toString();
    storeId = json['store_id'] != null ? (json['store_id'] as num).toInt() : null;
    taxId = json['tax_id'] != null ? (json['tax_id'] as num).toInt() : null;
    imageUrl = json['image_url']?.toString();
    isActive = json['isActive'] as bool?;  // ✅ ADD THIS LINE
    description = json['description']?.toString();
    displayOrder = json['display_order'] != null ? (json['display_order'] as num).toInt() : null;
    id = json['id'] != null ? (json['id'] as num).toInt() : null;
    tax = json['tax'] != null ? Tax.fromJson(json['tax']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['store_id'] = storeId;
    data['tax_id'] = taxId;
    data['image_url'] = imageUrl;
    data['isActive'] = isActive;
    data['description'] = description;
    data['display_order'] = displayOrder;
    data['id'] = id;
    if (tax != null) {
      data['tax'] = tax!.toJson();
    }

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
    price = json['price'] != null ? (json['price'] as num).toInt() : null;
    itemCode = json['item_code'];
    imageUrl = json['image_url'];
    description = json['description'];
    id = json['id'] != null ? (json['id'] as num).toInt() : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['price'] = price;
    data['item_code'] = itemCode;
    data['image_url'] = imageUrl;
    data['description'] = description;
    data['id'] = id;
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
    name = json['name']?.toString();
    percentage = json['percentage'] != null ? (json['percentage'] as num).toInt() : null;
    storeId = json['store_id'] != null ? (json['store_id'] as num).toInt() : null;
    id = json['id'] != null ? (json['id'] as num).toInt() : null;

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['percentage'] = percentage;
    data['store_id'] = storeId;
    data['id'] = id;
    return data;
  }
}
