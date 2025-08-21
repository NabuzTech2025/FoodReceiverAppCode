import 'dart:convert';

import 'BruttoSummary.dart';
import 'Discount.dart';
import 'Invoice.dart';
import 'OrderItem.dart';
import 'OrderUser.dart';
import 'Payment.dart';
import 'ShippingAddress.dart';
import 'TaxSummary.dart';

class Order {
  int? userId;
  int? discountId;
  String? note;
  int? shippingAddressId;
  int? billingAddressId;
  int? orderType;
  int? orderStatus;
  int? approvalStatus;
  DateTime? deliveryTime;
  int? storeId;
  bool? isActive;
  int? id;
  String? createdAt;
  OrderUser? user;
  List<OrderItem>? items;
  Discount? discount;
  Invoice? invoice;
  Payment? payment;
  int? code;
  String? mess;
  ShippingAddress? shipping_address;
  List<TaxSummary>? taxSummary;
  List<BruttoSummary>? brutto_netto_summary;
  GuestShippingJson? guestShippingJson;


  Order({
    this.userId,
    this.discountId,
    this.note,
    this.shippingAddressId,
    this.billingAddressId,
    this.orderType,
    this.orderStatus,
    this.approvalStatus,
    this.deliveryTime,
    this.storeId,
    this.isActive,
    this.id,
    this.createdAt,
    this.user,
    this.items,
    this.discount,
    this.invoice,
    this.payment,
    this.shipping_address,
    this.taxSummary,
    this.brutto_netto_summary,
    this.guestShippingJson
  });

  Order.withError({
    int? code,
    String? mess,
  })  : this.code = code,
        this.mess = mess;

  factory Order.fromJson(Map<String, dynamic> json) {
    print("Tax Summary Raw: ${json["tax_summary"]}");
    return Order(
      userId: json["user_id"],
      discountId: json["discount_id"],
      note: json["note"],
      shippingAddressId: json["shipping_address_id"],
      billingAddressId: json["billing_address_id"],
      orderType: json["order_type"],
      orderStatus: json["order_status"],
      approvalStatus: json["approval_status"],
      deliveryTime: json["delivery_time"],
      storeId: json["store_id"],
      isActive: json["isActive"],
      id: json["id"],
      createdAt: json["created_at"],
      user: json["user"] != null ? OrderUser.fromJson(json["user"]) : null,
      items: json["items"] != null
          ? List<OrderItem>.from(
              json["items"].map((x) => OrderItem.fromJson(x)))
          : [],
      discount:
          json["discount"] != null ? Discount.fromJson(json["discount"]) : null,
      invoice:
          json["invoice"] != null ? Invoice.fromJson(json["invoice"]) : null,
      payment:
          json["payment"] != null ? Payment.fromJson(json["payment"]) : null,
      shipping_address: json["shipping_address"] != null
          ? ShippingAddress.fromJson(json["shipping_address"])
          : null,
      taxSummary: json["tax_summary"] != null
          ? List<TaxSummary>.from(
              json["tax_summary"].map((x) => TaxSummary.fromJson(x)))
          : [],
      brutto_netto_summary: json["brutto_netto_summary"] != null
          ? List<BruttoSummary>.from(json["brutto_netto_summary"]
              .map((x) => BruttoSummary.fromJson(x)))
          : [],
      guestShippingJson:
      json["guest_shipping_json"] != null ? GuestShippingJson.fromJson(json["guest_shipping_json"]) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        "user_id": userId,
        "discount_id": discountId,
        "note": note,
        "shipping_address_id": shippingAddressId,
        "billing_address_id": billingAddressId,
        "order_type": orderType,
        "order_status": orderStatus,
        "approval_status": approvalStatus,
        "delivery_time": deliveryTime?.toIso8601String(),
        "store_id": storeId,
        "isActive": isActive,
        "id": id,
        "created_at": createdAt,
        "user": user?.toJson(),
        "items": items?.map((x) => x.toJson()).toList(),
        "discount": discount?.toJson(),
        "invoice": invoice?.toJson(),
        "payment": payment?.toJson(),
        "shipping_address": shipping_address?.toJson(),
        "tax_summary": taxSummary?.map((x) => x.toJson()).toList(),
        "brutto_netto_summary":
            brutto_netto_summary?.map((x) => x.toJson()).toList(),
    "guest_shipping_json": guestShippingJson?.toJson(),
      };

  static List<Order> fromJsonList(String str) =>
      List<Order>.from(json.decode(str).map((x) => Order.fromJson(x)));
}
class GuestShippingJson {
  String? zip;
  String? city;
  String? type;
  String? line1;
  String? phone;
  String? country;
  String? customerName;

  GuestShippingJson(
      {this.zip,
        this.city,
        this.type,
        this.line1,
        this.phone,
        this.country,
        this.customerName});

  GuestShippingJson.fromJson(Map<String, dynamic> json) {
    zip = json['zip'];
    city = json['city'];
    type = json['type'];
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
    data['line1'] = this.line1;
    data['phone'] = this.phone;
    data['country'] = this.country;
    data['customer_name'] = this.customerName;
    return data;
  }
}