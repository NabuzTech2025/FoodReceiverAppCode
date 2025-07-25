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
  })
      : this.code = code,
        this.mess = mess;

//   factory DailySalesReport.fromJson(Map<String, dynamic> json) {
//     return DailySalesReport(
//       storeId: json['store_id'],
//       type: json['type'],
//       startDate:json['start_date'],
//       endDate: json['end_date'],
//       isManual: json['is_manual'],
//       note: json['note'],
//       id: json['id'],
//       uniqueKey: json['unique_key'],
//       data: json['data'] != null ? SalesData.fromJson(json['data']) : null,
//       //data: SalesData.fromJson(json['data']),
//       totalSales: (json['total_sales'] as num).toDouble(),
//       totalOrders: json['total_orders'],
//       totalTax: (json['total_tax'] as num).toDouble(),
//       cashTotal: (json['cash_total'] as num).toDouble(),
//       onlineTotal: (json['online_total'] as num).toDouble(),
//       generatedBy: json['generated_by'],
//       generatedAt: json['generated_at'],
//     );
//   }
// }
  factory DailySalesReport.fromJson(Map<String, dynamic> json) {
    print("=== Parsing DailySalesReport ===");
    print("JSON keys: ${json.keys.toList()}");
    print("data field exists: ${json.containsKey('data')}");
    print("data is null: ${json['data'] == null}");

    try {
      var report = DailySalesReport(
        storeId: json['store_id'],
        type: json['type'],
        startDate: json['start_date'],
        endDate: json['end_date'],
        isManual: json['is_manual'],
        note: json['note'],
        id: json['id'],
        uniqueKey: json['unique_key'],
        data: json['data'] != null ? SalesData.fromJson(json['data']) : null,
        totalSales: json['total_sales'] != null ? (json['total_sales'] as num)
            .toDouble() : null,
        totalOrders: json['total_orders'],
        totalTax: json['total_tax'] != null ? (json['total_tax'] as num)
            .toDouble() : null,
        cashTotal: json['cash_total'] != null ? (json['cash_total'] as num)
            .toDouble() : null,
        onlineTotal: json['online_total'] != null
            ? (json['online_total'] as num).toDouble()
            : null,
        generatedBy: json['generated_by'],
        generatedAt: json['generated_at'],
      );

      print("DailySalesReport parsed successfully");
      print("totalSales: ${report.totalSales}");
      print("data is null: ${report.data == null}");
      return report;
    } catch (e, stackTrace) {
      print("ERROR parsing DailySalesReport: $e");
      print("StackTrace: $stackTrace");
      rethrow;
    }
  }
}
//
// class SalesData {
//   final List<TopItem> topItems;
//   final double cashTotal;
//   final Map<String, int> byCategory;
//   final Map<String, int> orderTypes;
//   final double totalSales;
//   final double onlineTotal;
//   final int totalOrders;
//   final Map<String, int> paymentMethods;
//   final Map<String, int> approvalStatuses;
//
//   SalesData({
//     required this.topItems,
//     required this.cashTotal,
//     required this.byCategory,
//     required this.orderTypes,
//     required this.totalSales,
//     required this.onlineTotal,
//     required this.totalOrders,
//     required this.paymentMethods,
//     required this.approvalStatuses,
//   });
//
//   factory SalesData.fromJson(Map<String, dynamic> json) {
//     return SalesData(
//       topItems: (json['top_items'] as List)
//           .map((item) => TopItem.fromJson(item))
//           .toList(),
//       cashTotal: (json['cash_total'] as num).toDouble(),
//       byCategory: Map<String, int>.from(json['by_category']),
//       orderTypes: Map<String, int>.from(json['order_types']),
//       totalSales: (json['total_sales'] as num).toDouble(),
//       onlineTotal: (json['online_total'] as num).toDouble(),
//       totalOrders: json['total_orders'],
//       paymentMethods: Map<String, int>.from(json['payment_methods']),
//       approvalStatuses: Map<String, int>.from(json['approval_statuses']),
//     );
//   }
// }
class SalesData {
  double? netTotal;
  final List<TopItem> topItems;
  double? totalTax;
  final double cashTotal;
  final Map<String, int> byCategory;
  final Map<String, int> orderTypes;
  final double totalSales;
  final double onlineTotal;
  final int totalOrders;
  TaxBreakdown? taxBreakdown;
  double? deliveryTotal;
  int? discountTotal;
  final Map<String, int> paymentMethods;
  final Map<String, int> approvalStatuses;
  double? totalSalesDelivery;

  SalesData({
    this.netTotal,
    required this.topItems,
    this.totalTax,
    required this.cashTotal,
    required this.byCategory,
    required this.orderTypes,
    required this.totalSales,
    required this.onlineTotal,
    required this.totalOrders,
    this.taxBreakdown,
    this.deliveryTotal,
    this.discountTotal,
    required this.paymentMethods,
    required this.approvalStatuses,
    this.totalSalesDelivery
  });

  factory SalesData.fromJson(Map<String, dynamic> json) {
    try {
      var netTotal = json['net_total'] != null
          ? (json['net_total'] as num).toDouble()
          : null;
      var topItems = (json['top_items'] as List)
          .map((item) => TopItem.fromJson(item))
          .toList();
      var totalTax = json['total_tax'] != null
          ? (json['total_tax'] as num).toDouble()
          : null;
      var cashTotal = (json['cash_total'] as num).toDouble();
      var byCategory = Map<String, int>.from(json['by_category']);
      var orderTypes = Map<String, int>.from(json['order_types']);
      var totalSales = (json['total_sales'] as num).toDouble();
      var onlineTotal = (json['online_total'] as num).toDouble();
      var totalOrders = json['total_orders'];
      var taxBreakdown = json['tax_breakdown'] != null
          ? TaxBreakdown.fromJson(json['tax_breakdown'])
          : null;
      var deliveryTotal = json['delivery_total'] != null
          ? (json['delivery_total'] as num).toDouble()
          : null;
      var discountTotal = json['discount_total'] != null
          ? (json['discount_total'] as num).toInt()  // Convert to int
          : null;
      var paymentMethods = Map<String, int>.from(json['payment_methods']);
      var approvalStatuses = Map<String, int>.from(json['approval_statuses']);
      var totalSalesDelivery = json['total_sales + delivery'] != null
          ? (json['total_sales + delivery'] as num).toDouble()
          : null;
      return SalesData(
        netTotal: netTotal,
        topItems: topItems,
        totalTax: totalTax,
        cashTotal: cashTotal,
        byCategory: byCategory,
        orderTypes: orderTypes,
        totalSales: totalSales,
        onlineTotal: onlineTotal,
        totalOrders: totalOrders,
        taxBreakdown: taxBreakdown,
        deliveryTotal: deliveryTotal,
        discountTotal: discountTotal,
        paymentMethods: paymentMethods,
        approvalStatuses: approvalStatuses,
        totalSalesDelivery: totalSalesDelivery,
      );

    } catch (e, stackTrace) {
      print("ERROR parsing SalesData: $e");
      print("StackTrace: $stackTrace");
      rethrow;
    }
  }
}

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
  // Change from int? to double? - this is the main fix
  double? i0;  // Changed from int? to double?
  double? d1;
  double? d7;

  TaxBreakdown({this.i0, this.d1, this.d7});

  // Fix the constructor - add factory keyword and proper null handling
  factory TaxBreakdown.fromJson(Map<String, dynamic> json) {
    return TaxBreakdown(
      i0: json['0'] != null ? (json['0'] as num).toDouble() : null,
      d1: json['1'] != null ? (json['1'] as num).toDouble() : null,
      d7: json['7'] != null ? (json['7'] as num).toDouble() : null,
    );
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
