class GetAdminReportResponseModel {
  String? generatedAt;
  int? totalStores;
  List<Reports>? reports;

  GetAdminReportResponseModel(
      {this.generatedAt, this.totalStores, this.reports});

  GetAdminReportResponseModel.fromJson(Map<String, dynamic> json) {
    generatedAt = json['generated_at'];
    totalStores = json['total_stores'];
    if (json['reports'] != null) {
      reports = <Reports>[];
      json['reports'].forEach((v) {
        reports!.add(new Reports.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['generated_at'] = this.generatedAt;
    data['total_stores'] = this.totalStores;
    if (this.reports != null) {
      data['reports'] = this.reports!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Reports {
  int? storeId;
  String? storeName;
  bool? hasData;
  Report? report;

  Reports({this.storeId, this.storeName, this.hasData, this.report});

  Reports.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    storeName = json['store_name'];
    hasData = json['has_data'];
    report =
    json['report'] != null ? new Report.fromJson(json['report']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['store_id'] = this.storeId;
    data['store_name'] = this.storeName;
    data['has_data'] = this.hasData;
    if (this.report != null) {
      data['report'] = this.report!.toJson();
    }
    return data;
  }
}

class Report {
  double? totalSales;
  int? totalOrders;
  double? cashTotal;
  double? onlineTotal;
  double? discountTotal;
  double? deliveryTotal;
  double? totalTax;
  double? netTotal;
  TaxBreakdown? taxBreakdown;
  PaymentMethods? paymentMethods;
  OrderTypes? orderTypes;
  ApprovalStatuses? approvalStatuses;
  List<TopItems>? topItems;
  ByCategory? byCategory;
  double? totalSalesDelivery;
  List<DetailedOrders>? detailedOrders;

  Report(
      {this.totalSales,
        this.totalOrders,
        this.cashTotal,
        this.onlineTotal,
        this.discountTotal,
        this.deliveryTotal,
        this.totalTax,
        this.netTotal,
        this.taxBreakdown,
        this.paymentMethods,
        this.orderTypes,
        this.approvalStatuses,
        this.topItems,
        this.byCategory,
        this.totalSalesDelivery,
        this.detailedOrders});

  Report.fromJson(Map<String, dynamic> json) {
    totalSales = json['total_sales'];
    totalOrders = json['total_orders'];
    cashTotal = json['cash_total'];
    onlineTotal = json['online_total'];
    discountTotal = json['discount_total'];
    deliveryTotal = json['delivery_total'];
    totalTax = json['total_tax'];
    netTotal = json['net_total'];
    taxBreakdown = json['tax_breakdown'] != null
        ? new TaxBreakdown.fromJson(json['tax_breakdown'])
        : null;
    paymentMethods = json['payment_methods'] != null
        ? new PaymentMethods.fromJson(json['payment_methods'])
        : null;
    orderTypes = json['order_types'] != null
        ? new OrderTypes.fromJson(json['order_types'])
        : null;
    approvalStatuses = json['approval_statuses'] != null
        ? new ApprovalStatuses.fromJson(json['approval_statuses'])
        : null;
    if (json['top_items'] != null) {
      topItems = <TopItems>[];
      json['top_items'].forEach((v) {
        topItems!.add(new TopItems.fromJson(v));
      });
    }
    byCategory = json['by_category'] != null
        ? new ByCategory.fromJson(json['by_category'])
        : null;
    totalSalesDelivery = json['total_sales + delivery'];
    if (json['detailed_orders'] != null) {
      detailedOrders = <DetailedOrders>[];
      json['detailed_orders'].forEach((v) {
        detailedOrders!.add(new DetailedOrders.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['total_sales'] = this.totalSales;
    data['total_orders'] = this.totalOrders;
    data['cash_total'] = this.cashTotal;
    data['online_total'] = this.onlineTotal;
    data['discount_total'] = this.discountTotal;
    data['delivery_total'] = this.deliveryTotal;
    data['total_tax'] = this.totalTax;
    data['net_total'] = this.netTotal;
    if (this.taxBreakdown != null) {
      data['tax_breakdown'] = this.taxBreakdown!.toJson();
    }
    if (this.paymentMethods != null) {
      data['payment_methods'] = this.paymentMethods!.toJson();
    }
    if (this.orderTypes != null) {
      data['order_types'] = this.orderTypes!.toJson();
    }
    if (this.approvalStatuses != null) {
      data['approval_statuses'] = this.approvalStatuses!.toJson();
    }
    if (this.topItems != null) {
      data['top_items'] = this.topItems!.map((v) => v.toJson()).toList();
    }
    if (this.byCategory != null) {
      data['by_category'] = this.byCategory!.toJson();
    }
    data['total_sales + delivery'] = this.totalSalesDelivery;
    if (this.detailedOrders != null) {
      data['detailed_orders'] =
          this.detailedOrders!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class TaxBreakdown {
  double? d7;
  double? d19;

  TaxBreakdown({this.d7});

  TaxBreakdown.fromJson(Map<String, dynamic> json) {
    d7 = json['7'];
    d7 = json['19'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['7'] = this.d7;
    data['19'] = this.d19;
    return data;
  }
}

class PaymentMethods {
  int? cash;

  PaymentMethods({this.cash});

  PaymentMethods.fromJson(Map<String, dynamic> json) {
    cash = json['cash'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['cash'] = this.cash;
    return data;
  }
}

class OrderTypes {
  int? delivery;
  int? pickup;
  int? dineIn;

  OrderTypes({this.delivery, this.pickup, this.dineIn});

  OrderTypes.fromJson(Map<String, dynamic> json) {
    delivery = json['delivery'];
    pickup = json['pickup'];
    dineIn = json['dine_in'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['delivery'] = this.delivery;
    data['pickup'] = this.pickup;
    data['dine_in'] = this.dineIn;
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

class TopItems {
  String? name;
  int? qty;
  double? revenue;

  TopItems({this.name, this.qty, this.revenue});

  TopItems.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    qty = json['qty'];
    revenue = json['revenue'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['qty'] = this.qty;
    data['revenue'] = this.revenue;
    return data;
  }
}

class ByCategory {
  int? fleischgerichte;

  ByCategory({this.fleischgerichte});

  ByCategory.fromJson(Map<String, dynamic> json) {
    fleischgerichte = json['Fleischgerichte'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Fleischgerichte'] = this.fleischgerichte;
    return data;
  }
}

class DetailedOrders {
  String? invoiceNumber;
  String? orderType;
  double? total;

  DetailedOrders({this.invoiceNumber, this.orderType, this.total});

  DetailedOrders.fromJson(Map<String, dynamic> json) {
    invoiceNumber = json['invoice_number'];
    orderType = json['order_type'];
    total = json['total'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['invoice_number'] = this.invoiceNumber;
    data['order_type'] = this.orderType;
    data['total'] = this.total;
    return data;
  }
}