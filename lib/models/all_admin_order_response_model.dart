class AllOrderAdminResponseModel {
  int? userId;
  int? discountId;
  String? note;
  int? orderType;
  int? orderStatus;
  int? approvalStatus;
  String? deliveryTime;
  int? storeId;
  bool? isActive;
  int? id;
  String? createdAt;
  String? storeName;
  int? orderNumber;
  User? user;
  List<Items>? items;
  Discount? discount;
  Invoice? invoice;
  Payment? payment;
  ShippingAddress? shippingAddress;
  ShippingAddress? billingAddress;
  List<TaxSummary>? taxSummary;
  List<BruttoNettoSummary>? bruttoNettoSummary;
  GuestShippingJson? guestShippingJson;

  AllOrderAdminResponseModel(
      {this.userId,
        this.discountId,
        this.note,
        this.orderType,
        this.orderStatus,
        this.approvalStatus,
        this.deliveryTime,
        this.storeId,
        this.isActive,
        this.id,
        this.createdAt,
        this.storeName,
        this.orderNumber,
        this.user,
        this.items,
        this.discount,
        this.invoice,
        this.payment,
        this.shippingAddress,
        this.billingAddress,
        this.taxSummary,
        this.bruttoNettoSummary,
        this.guestShippingJson});

  AllOrderAdminResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      userId = json['user_id'] as int?;
      discountId = json['discount_id'] as int?;
      note = json['note'] as String?;
      orderType = json['order_type'] as int?;
      orderStatus = json['order_status'] as int?;
      approvalStatus = json['approval_status'] as int?;
      deliveryTime = json['delivery_time'] as String?;
      storeId = json['store_id'] as int?;
      isActive = json['isActive'] as bool?;
      id = json['id'] as int?;
      createdAt = json['created_at'] as String?;
      storeName = json['store_name'];
      orderNumber = json['order_number'] as int?;
      user = json['user'] != null ? User.fromJson(json['user']) : null;

      if (json['items'] != null && json['items'] is List) {
        items = <Items>[];
        (json['items'] as List).forEach((v) {
          try {
            items!.add(Items.fromJson(v));
          } catch (e) {
            print("Error parsing item: $e");
          }
        });
      }

      discount = json['discount'] != null && json['discount'] is Map
          ? Discount.fromJson(json['discount'])
          : null;

      invoice = json['invoice'] != null && json['invoice'] is Map
          ? Invoice.fromJson(json['invoice'])
          : null;

      payment = json['payment'] != null && json['payment'] is Map
          ? Payment.fromJson(json['payment'])
          : null;

      shippingAddress = json['shipping_address'] != null && json['shipping_address'] is Map
          ? ShippingAddress.fromJson(json['shipping_address'])
          : null;

      billingAddress = json['billing_address'] != null && json['billing_address'] is Map
          ? ShippingAddress.fromJson(json['billing_address'])
          : null;

      if (json['tax_summary'] != null && json['tax_summary'] is List) {
        taxSummary = <TaxSummary>[];
        (json['tax_summary'] as List).forEach((v) {
          try {
            taxSummary!.add(TaxSummary.fromJson(v));
          } catch (e) {
            print("Error parsing tax summary: $e");
          }
        });
      }

      if (json['brutto_netto_summary'] != null && json['brutto_netto_summary'] is List) {
        bruttoNettoSummary = <BruttoNettoSummary>[];
        (json['brutto_netto_summary'] as List).forEach((v) {
          try {
            bruttoNettoSummary!.add(BruttoNettoSummary.fromJson(v));
          } catch (e) {
            print("Error parsing brutto netto summary: $e");
          }
        });
      }

      guestShippingJson = json['guest_shipping_json'] != null && json['guest_shipping_json'] is Map
          ? GuestShippingJson.fromJson(json['guest_shipping_json'])
          : null;

    } catch (e) {
      print("Error in AllOrderAdminResponseModel.fromJson: $e");
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user_id'] = this.userId;
    data['discount_id'] = this.discountId;
    data['note'] = this.note;
    data['order_type'] = this.orderType;
    data['order_status'] = this.orderStatus;
    data['approval_status'] = this.approvalStatus;
    data['delivery_time'] = this.deliveryTime;
    data['store_id'] = this.storeId;
    data['isActive'] = this.isActive;
    data['id'] = this.id;
    data['created_at'] = this.createdAt;
    data['store_name'] = this.storeName;
    data['order_number'] = this.orderNumber;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    if (this.items != null) {
      data['items'] = this.items!.map((v) => v.toJson()).toList();
    }
    if (this.discount != null) {
      data['discount'] = this.discount!.toJson();
    }
    if (this.invoice != null) {
      data['invoice'] = this.invoice!.toJson();
    }
    if (this.payment != null) {
      data['payment'] = this.payment!.toJson();
    }
    if (this.shippingAddress != null) {
      data['shipping_address'] = this.shippingAddress!.toJson();
    }
    if (this.billingAddress != null) {
      data['billing_address'] = this.billingAddress!.toJson();
    }
    if (this.taxSummary != null) {
      data['tax_summary'] = this.taxSummary!.map((v) => v.toJson()).toList();
    }
    if (this.bruttoNettoSummary != null) {
      data['brutto_netto_summary'] =
          this.bruttoNettoSummary!.map((v) => v.toJson()).toList();
    }
    if (this.guestShippingJson != null) {
      data['guest_shipping_json'] = this.guestShippingJson!.toJson();
    }
    return data;
  }
}

class Items {
  int? productId;
  int? variantId;
  int? quantity;
  double? unitPrice;
  String? note;
  int? id;
  String? variant;
  String? productName;
  String? variantName;
  double? tax;
  List<Toppings>? toppings;

  Items(
      {this.productId,
        this.variantId,
        this.quantity,
        this.unitPrice,
        this.note,
        this.id,
        this.variant,
        this.productName,
        this.variantName,
        this.tax,
        this.toppings
      });

  Items.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'] as int?;
    variantId = json['variant_id'];  // Already nullable
    quantity = json['quantity'] as int?;
    unitPrice = json['unit_price'] != null ? (json['unit_price'] as num).toDouble() : null;
    note = json['note'] as String?;
    id = json['id'] as int?;
    variant = json['variant'] as String?;
    productName = json['product_name'] as String?;
    variantName = json['variant_name'] as String?;
    tax = json['tax'] != null ? (json['tax'] as num).toDouble() : null;
    if (json['toppings'] != null) {
      toppings = <Toppings>[];
      json['toppings'].forEach((v) {
        toppings!.add(new Toppings.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['product_id'] = this.productId;
    data['variant_id'] = this.variantId;
    data['quantity'] = this.quantity;
    data['unit_price'] = this.unitPrice;
    data['note'] = this.note;
    data['id'] = this.id;
    data['variant'] = this.variant;
    data['product_name'] = this.productName;
    data['variant_name'] = this.variantName;
    data['tax'] = this.tax;
    if (this.toppings != null) {
      data['toppings'] = this.toppings!.map((v) => v.toJson()).toList();
    }
    return data;
  }

}

class Discount {
  String? code;
  String? type;
  double? value;
  String? expiresAt;
  int? storeId;
  int? id;

  Discount(
      {this.code,
        this.type,
        this.value,
        this.expiresAt,
        this.storeId,
        this.id});

  Discount.fromJson(Map<String, dynamic> json) {
    code = json['code'] as String?;
    type = json['type'] as String?;
    value = json['value'] != null ? (json['value'] as num).toDouble() : null;  // ✅
    expiresAt = json['expires_at'] as String?;
    storeId = json['store_id'] as int?;  // ✅ Make nullable
    id = json['id'] as int?;  // ✅ Make nullable
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['code'] = this.code;
    data['type'] = this.type;
    data['value'] = this.value;
    data['expires_at'] = this.expiresAt;
    data['store_id'] = this.storeId;
    data['id'] = this.id;
    return data;
  }
}

class Invoice {
  String? invoiceNumber;
  double? totalAmount;
  String? issuedAt;
  int? storeId;
  int? id;
  int? orderId;
  double? deliveryFee;
  double? discountAmount;

  Invoice(
      {this.invoiceNumber,
        this.totalAmount,
        this.issuedAt,
        this.storeId,
        this.id,
        this.orderId,
        this.deliveryFee,
        this.discountAmount});

  Invoice.fromJson(Map<String, dynamic> json) {
    invoiceNumber = json['invoice_number'] as String?;
    totalAmount = json['total_amount'] != null ? (json['total_amount'] as num).toDouble() : null;
    issuedAt = json['issued_at'] as String?;
    storeId = json['store_id'] as int?;
    id = json['id'] as int?;
    orderId = json['order_id'] as int?;
    deliveryFee = json['delivery_fee'] != null ? (json['delivery_fee'] as num).toDouble() : null;
    discountAmount = json['discount_amount'] != null ? (json['discount_amount'] as num).toDouble() : null;
  }


  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['invoice_number'] = this.invoiceNumber;
    data['total_amount'] = this.totalAmount;
    data['issued_at'] = this.issuedAt;
    data['store_id'] = this.storeId;
    data['id'] = this.id;
    data['order_id'] = this.orderId;
    data['delivery_fee'] = this.deliveryFee;
    data['discount_amount'] = this.discountAmount;
    return data;
  }
}

class Payment {
  String? paymentMethod;
  String? status;
  String? paidAt;
  double? amount;
  int? id;
  int? orderId;

  Payment(
      {this.paymentMethod,
        this.status,
        this.paidAt,
        this.amount,
        this.id,
        this.orderId});

  Payment.fromJson(Map<String, dynamic> json) {
    paymentMethod = json['payment_method'] as String?;
    status = json['status'] as String?;
    paidAt = json['paid_at'] as String?;
    amount = json['amount'] != null ? (json['amount'] as num).toDouble() : null;
    id = json['id'] as int?;
    orderId = json['order_id'] as int?;
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['payment_method'] = this.paymentMethod;
    data['status'] = this.status;
    data['paid_at'] = this.paidAt;
    data['amount'] = this.amount;
    data['id'] = this.id;
    data['order_id'] = this.orderId;
    return data;
  }
}

class TaxSummary {
  double? taxRate;
  double? taxAmount;

  TaxSummary({this.taxRate, this.taxAmount});

  TaxSummary.fromJson(Map<String, dynamic> json) {
    taxRate = (json['tax_rate'] as num?)?.toDouble();  // ✅ Changed
    taxAmount = (json['tax_amount'] as num?)?.toDouble();  // ✅ Changed
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tax_rate'] = this.taxRate;
    data['tax_amount'] = this.taxAmount;
    return data;
  }
}

class BruttoNettoSummary {
  double? taxRate;
  double? brutto;
  double? netto;
  double? taxAmount;

  BruttoNettoSummary({this.taxRate, this.brutto, this.netto, this.taxAmount});

  BruttoNettoSummary.fromJson(Map<String, dynamic> json) {
    taxRate = (json['tax_rate'] as num?)?.toDouble();  // ✅ Changed
    brutto = (json['brutto'] as num?)?.toDouble();  // ✅ Changed
    netto = (json['netto'] as num?)?.toDouble();  // ✅ Changed
    taxAmount = (json['tax_amount'] as num?)?.toDouble();  // ✅ Changed
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['tax_rate'] = this.taxRate;
    data['brutto'] = this.brutto;
    data['netto'] = this.netto;
    data['tax_amount'] = this.taxAmount;
    return data;
  }
}

class GuestShippingJson {
  String? zip;
  String? city;
  String? type;
  String? email;
  String? line1;
  String? phone;
  String? country;
  String? customerName;

  GuestShippingJson(
      {this.zip,
        this.city,
        this.type,
        this.email,
        this.line1,
        this.phone,
        this.country,
        this.customerName});

  GuestShippingJson.fromJson(Map<String, dynamic> json) {
    zip = json['zip'];
    city = json['city'];
    type = json['type'];
    email = json['email'];
    line1 = json['line1'];
    phone = json['phone'];
    country = json['country'];
    customerName = json['customer_name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['zip'] = this.zip;
    data['city'] = this.city;
    data['type'] = this.type;
    data['email'] = this.email;
    data['line1'] = this.line1;
    data['phone'] = this.phone;
    data['country'] = this.country;
    data['customer_name'] = this.customerName;
    return data;
  }
}
class User {
  String? username;
  int? id;
  int? storeId;
  int? roleId;

  User({this.username, this.id, this.storeId, this.roleId});

  User.fromJson(Map<String, dynamic> json) {
    username = json['username'] as String?;
    id = json['id'] as int?;
    storeId = json['store_id'] as int?;
    roleId = json['role_id'] as int?;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['username'] = this.username;
    data['id'] = this.id;
    data['store_id'] = this.storeId;
    data['role_id'] = this.roleId;
    return data;
  }
}
class ShippingAddress {
  String? type;
  String? line1;
  String? city;
  String? zip;
  String? country;
  String? phone;
  String? customerName;
  int? id;
  int? userId;

  ShippingAddress({
    this.type,
    this.line1,
    this.city,
    this.zip,
    this.country,
    this.phone,
    this.customerName,
    this.id,
    this.userId,
  });

  ShippingAddress.fromJson(Map<String, dynamic> json) {
    type = json['type'];
    line1 = json['line1'];
    city = json['city'];
    zip = json['zip'];
    country = json['country'];
    phone = json['phone'];
    customerName = json['customer_name'];
    id = json['id'];
    userId = json['user_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['line1'] = this.line1;
    data['city'] = this.city;
    data['zip'] = this.zip;
    data['country'] = this.country;
    data['phone'] = this.phone;
    data['customer_name'] = this.customerName;
    data['id'] = this.id;
    data['user_id'] = this.userId;
    return data;
  }
}

class Toppings {
  int? toppingId;
  int? quantity;
  int? price;
  String? name;

  Toppings({this.toppingId, this.quantity, this.price, this.name});

  Toppings.fromJson(Map<String, dynamic> json) {
    toppingId = json['topping_id'];
    quantity = json['quantity'];
    price = json['price'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['topping_id'] = this.toppingId;
    data['quantity'] = this.quantity;
    data['price'] = this.price;
    data['name'] = this.name;
    return data;
  }
}