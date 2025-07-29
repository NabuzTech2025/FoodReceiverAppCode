class GetTodayReport {
  double? totalSales;
  int? totalOrders;
  double? cashTotal;
  double? onlineTotal;  // Changed from int? to double?
  double? discountTotal; // Changed from int? to double?
  double? deliveryTotal; // Changed from int? to double?
  double? totalTax;
  double? netTotal;
  TaxBreakdown? taxBreakdown;
  PaymentMethods? paymentMethods;
  OrderTypes? orderTypes;
  ApprovalStatuses? approvalStatuses;
  List<TopItems>? topItems;
  ByCategory? byCategory;
  double? totalSalesDelivery;
  int? code;
  String? mess;

  GetTodayReport(
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
        this.totalSalesDelivery});

  GetTodayReport.withError({
    int? code,
    String? mess,
  })
      : this.code = code,
        this.mess = mess;

  GetTodayReport.fromJson(Map<String, dynamic> json) {
    totalSales = json['total_sales']?.toDouble();
    totalOrders = json['total_orders']?.toInt();
    cashTotal = json['cash_total']?.toDouble();
    onlineTotal = json['online_total']?.toDouble(); // Safe conversion to double
    discountTotal = json['discount_total']?.toDouble(); // Safe conversion to double
    deliveryTotal = json['delivery_total']?.toDouble(); // Safe conversion to double
    totalTax = json['total_tax']?.toDouble();
    netTotal = json['net_total']?.toDouble();
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
    totalSalesDelivery = json['total_sales + delivery']?.toDouble();
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
    return data;
  }
}

class TaxBreakdown {
  double? d7;
  double? d19;

  TaxBreakdown({this.d7, this.d19});

  TaxBreakdown.fromJson(Map<String, dynamic> json) {
    d7 = json['7'];
    d19 = json['19'];
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
  int? pizzaCa29O;
  int? fingerfood;
  int? alkoholfreieGetrNke;
  int? fR2Personen;
  int? fleischgerichte;
  int? frischeSalate;

  ByCategory(
      {this.pizzaCa29O,
        this.fingerfood,
        this.alkoholfreieGetrNke,
        this.fR2Personen,
        this.fleischgerichte,
        this.frischeSalate});

  ByCategory.fromJson(Map<String, dynamic> json) {
    pizzaCa29O = json['Pizza ca 29 O'];
    fingerfood = json['Fingerfood'];
    alkoholfreieGetrNke = json['Alkoholfreie Getränke'];
    fR2Personen = json['Für 2 Personen'];
    fleischgerichte = json['Fleischgerichte'];
    frischeSalate = json['Frische Salate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Pizza ca 29 O'] = this.pizzaCa29O;
    data['Fingerfood'] = this.fingerfood;
    data['Alkoholfreie Getränke'] = this.alkoholfreieGetrNke;
    data['Für 2 Personen'] = this.fR2Personen;
    data['Fleischgerichte'] = this.fleischgerichte;
    data['Frische Salate'] = this.frischeSalate;
    return data;
  }
}