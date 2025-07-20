class DailySalesReport {
  int? storeId;
  String? type;
  String? startDate;
  String? endDate;
  bool? isManual;
  String? note;
  int? id;
  String? uniqueKey;
  SalesData? data;
  double? totalSales;
  int? totalOrders;
  double? totalTax;
  double? cashTotal;
  double? onlineTotal;
  int? generatedBy;
  String? generatedAt;
  int? code;
  String? mess;

  DailySalesReport({
    this.storeId,
    this.type,
    this.startDate,
    this.endDate,
    this.isManual,
    this.note,
    this.id,
    this.uniqueKey,
    this.data,
    this.totalSales,
    this.totalOrders,
    this.totalTax,
    this.cashTotal,
    this.onlineTotal,
    this.generatedBy,
    this.generatedAt,
  });

  DailySalesReport.withError({
    int? code,
    String? mess,
  })  : this.code = code,
        this.mess = mess;

  factory DailySalesReport.fromJson(Map<String, dynamic> json) {
    return DailySalesReport(
      storeId: json['store_id'],
      type: json['type'],
      startDate:json['start_date'],
      endDate: json['end_date'],
      isManual: json['is_manual'],
      note: json['note'],
      id: json['id'],
      uniqueKey: json['unique_key'],
      data: SalesData.fromJson(json['data']),
      totalSales: (json['total_sales'] as num).toDouble(),
      totalOrders: json['total_orders'],
      totalTax: (json['total_tax'] as num).toDouble(),
      cashTotal: (json['cash_total'] as num).toDouble(),
      onlineTotal: (json['online_total'] as num).toDouble(),
      generatedBy: json['generated_by'],
      generatedAt: json['generated_at'],
    );
  }
}

class SalesData {
  final List<TopItem> topItems;
  final double cashTotal;
  final Map<String, int> byCategory;
  final Map<String, int> orderTypes;
  final double totalSales;
  final double onlineTotal;
  final int totalOrders;
  final Map<String, int> paymentMethods;
  final Map<String, int> approvalStatuses;

  SalesData({
    required this.topItems,
    required this.cashTotal,
    required this.byCategory,
    required this.orderTypes,
    required this.totalSales,
    required this.onlineTotal,
    required this.totalOrders,
    required this.paymentMethods,
    required this.approvalStatuses,
  });

  factory SalesData.fromJson(Map<String, dynamic> json) {
    return SalesData(
      topItems: (json['top_items'] as List)
          .map((item) => TopItem.fromJson(item))
          .toList(),
      cashTotal: (json['cash_total'] as num).toDouble(),
      byCategory: Map<String, int>.from(json['by_category']),
      orderTypes: Map<String, int>.from(json['order_types']),
      totalSales: (json['total_sales'] as num).toDouble(),
      onlineTotal: (json['online_total'] as num).toDouble(),
      totalOrders: json['total_orders'],
      paymentMethods: Map<String, int>.from(json['payment_methods']),
      approvalStatuses: Map<String, int>.from(json['approval_statuses']),
    );
  }
}
// class SalesData {
//   int? netTotal;
//   List<TopItem>? topItems;
//   final double totalTax;
//   final double cashTotal;
//   final Map<String, int> byCategory;
//   final Map<String, int> orderTypes; // Updated from Map to Class
//   final double totalSales;
//   final double onlineTotal;
//   final int totalOrders;
//   TaxBreakdown? taxBreakdown;
//   final double deliveryTotal;
//   final int discountTotal;
//   final Map<String, int> paymentMethods;
//   final Map<String, int> approvalStatuses; // Updated from Map to Class
//   final double totalSalesDelivery; // New field added
//
//   SalesData({
//     required this.netTotal,
//     required this.topItems,
//     required this.totalTax,
//     required this.cashTotal,
//     required this.byCategory,
//     required this.orderTypes,
//     required this.totalSales,
//     required this.onlineTotal,
//     required this.totalOrders,
//     required this.taxBreakdown,
//     required this.deliveryTotal,
//     required this.discountTotal,
//     required this.paymentMethods,
//     required this.approvalStatuses,
//     required this.totalSalesDelivery,
//   });
//
//   factory SalesData.fromJson(Map<String, dynamic> json) {
//     return SalesData(
//       netTotal: json['net_total'],
//       topItems: (json['top_items'] as List<dynamic>?)
//           ?.map((e) => TopItem.fromJson(e))
//           .toList(),
//       totalTax: (json['total_tax'] as num?)!.toDouble(),
//       cashTotal: (json['cash_total'] as num).toDouble(),
//       byCategory: Map<String, int>.from(json['by_category']),
//       orderTypes: Map<String, int>.from(json['order_types']),
//       totalSales: (json['total_sales'] as num).toDouble(),
//       onlineTotal: (json['online_total'] as num).toDouble(),
//       totalOrders: json['total_orders'],
//       paymentMethods: Map<String, int>.from(json['payment_methods']),
//       approvalStatuses: Map<String, int>.from(json['approval_statuses']),
//       // onlineTotal: (json['online_total'] as num?)?.toDouble(),
//       // totalOrders: json['total_orders'],
//       taxBreakdown: json['tax_breakdown'] != null
//           ? TaxBreakdown.fromJson(json['tax_breakdown'])
//           : null,
//       deliveryTotal: (json['delivery_total'] as num?)!.toDouble(),
//       discountTotal: json['discount_total'],
//       //    paymentMethods: Map<String, int>.from(json['payment_methods']),
//       // approvalStatuses: Map<String, int>.from(json['approval_statuses']),
//       totalSalesDelivery: (json['total_sales + delivery'] as num?)!.toDouble(),
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     final data = <String, dynamic>{};
//     data['net_total'] = netTotal;
//     data['top_items'] = topItems?.map((e) => e.toJson()).toList();
//     data['total_tax'] = totalTax;
//     data['cash_total'] = cashTotal;
//     data['by_category'] = byCategory; // <-- Remove .toJson()
//     data['order_types'] = orderTypes; // <-- Remove .toJson()
//     data['total_sales'] = totalSales;
//     data['online_total'] = onlineTotal;
//     data['total_orders'] = totalOrders;
//     if (taxBreakdown != null) data['tax_breakdown'] = taxBreakdown!.toJson();
//     data['delivery_total'] = deliveryTotal;
//     data['discount_total'] = discountTotal;
//     data['payment_methods'] = paymentMethods; // <-- Remove .toJson()
//     data['approval_statuses'] = approvalStatuses; // <-- Remove .toJson()
//     data['total_sales + delivery'] = totalSalesDelivery;
//     return data;
//   }
// }

class TopItem {
  final int qty;
  final String name;
  final double revenue;

  TopItem({
    required this.qty,
    required this.name,
    required this.revenue,
  });

  factory TopItem.fromJson(Map<String, dynamic> json) {
    return TopItem(
      qty: json['qty'],
      name: json['name'],
      revenue: (json['revenue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qty': qty,
      'name': name,
      'revenue': revenue,
    };
  }
}
class TaxBreakdown {
  int? i0;
  double? d1;
  double? d7;

  TaxBreakdown({this.i0, this.d1, this.d7});

  TaxBreakdown.fromJson(Map<String, dynamic> json) {
    i0 = json['0'];
    d1 = json['1'];
    d7 = json['7'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['0'] = this.i0;
    data['1'] = this.d1;
    data['7'] = this.d7;
    return data;
  }
}

class PaymentMethods {
  int? cash;
  int? online;

  PaymentMethods({this.cash, this.online});

  PaymentMethods.fromJson(Map<String, dynamic> json) {
    cash = json['cash'];
    online = json['online'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['cash'] = this.cash;
    data['online'] = this.online;
    return data;
  }
}

class ApprovalStatuses {
  int? pending;
  int? accepted;
  int? declined;

  ApprovalStatuses({this.pending, this.accepted, this.declined});

  ApprovalStatuses.fromJson(Map<String, dynamic> json) {
    pending = json['pending'];
    accepted = json['accepted'];
    declined = json['declined'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['pending'] = this.pending;
    data['accepted'] = this.accepted;
    data['declined'] = this.declined;
    return data;
  }
}
