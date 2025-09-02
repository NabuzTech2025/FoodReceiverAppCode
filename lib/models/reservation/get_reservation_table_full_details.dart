class GetOrderDetailsResponseModel {
  int? storeId;
  int? userId;
  int? guestCount;
  String? reservedFor;
  String? reservedUntil;
  String? status;
  int? tableNumber;
  String? customerName;
  String? customerPhone;
  String? customerEmail;
  String? note;
  bool? isActive;
  int? id;
  String? createdAt;
  int? user;

  GetOrderDetailsResponseModel(
      {this.storeId,
        this.userId,
        this.guestCount,
        this.reservedFor,
        this.reservedUntil,
        this.status,
        this.tableNumber,
        this.customerName,
        this.customerPhone,
        this.customerEmail,
        this.note,
        this.isActive,
        this.id,
        this.createdAt,
        this.user});

  GetOrderDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    storeId = json['store_id'];
    userId = json['user_id'];
    guestCount = json['guest_count'];
    reservedFor = json['reserved_for'];
    reservedUntil = json['reserved_until'];
    status = json['status'];
    tableNumber = json['table_number'];
    customerName = json['customer_name'];
    customerPhone = json['customer_phone'];
    customerEmail = json['customer_email'];
    note = json['note'];
    isActive = json['isActive'];
    id = json['id'];
    createdAt = json['created_at'];
    user = json['user'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['store_id'] = this.storeId;
    data['user_id'] = this.userId;
    data['guest_count'] = this.guestCount;
    data['reserved_for'] = this.reservedFor;
    data['reserved_until'] = this.reservedUntil;
    data['status'] = this.status;
    data['table_number'] = this.tableNumber;
    data['customer_name'] = this.customerName;
    data['customer_phone'] = this.customerPhone;
    data['customer_email'] = this.customerEmail;
    data['note'] = this.note;
    data['isActive'] = this.isActive;
    data['id'] = this.id;
    data['created_at'] = this.createdAt;
    data['user'] = this.user;
    return data;
  }
}