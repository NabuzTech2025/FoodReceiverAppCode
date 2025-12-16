class SyncLocalOrder {
  String? status;
  int? limit;
  int? offset;
  int? processed;
  List<int>? syncedOrderIds;

  SyncLocalOrder(
      {this.status,
        this.limit,
        this.offset,
        this.processed,
        this.syncedOrderIds});

  SyncLocalOrder.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    limit = json['limit'];
    offset = json['offset'];
    processed = json['processed'];
    syncedOrderIds = json['synced_order_ids'].cast<int>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['limit'] = this.limit;
    data['offset'] = this.offset;
    data['processed'] = this.processed;
    data['synced_order_ids'] = this.syncedOrderIds;
    return data;
  }
}