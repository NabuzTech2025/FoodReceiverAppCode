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
}
