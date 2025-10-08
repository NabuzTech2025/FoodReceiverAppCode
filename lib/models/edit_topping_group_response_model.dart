class EditToppingsGroupResponseModel {
  String? name;
  int? minSelect;
  int? maxSelect;
  bool? isRequired;
  int? storeId;
  int? id;
  bool? isActive;

  EditToppingsGroupResponseModel(
      {this.name,
        this.minSelect,
        this.maxSelect,
        this.isRequired,
        this.storeId,
        this.id,
        this.isActive});

  EditToppingsGroupResponseModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    minSelect = json['min_select'];
    maxSelect = json['max_select'];
    isRequired = json['is_required'];
    storeId = json['store_id'];
    id = json['id'];
    isActive = json['isActive'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['min_select'] = this.minSelect;
    data['max_select'] = this.maxSelect;
    data['is_required'] = this.isRequired;
    data['store_id'] = this.storeId;
    data['id'] = this.id;
    data['isActive'] = this.isActive;
    return data;
  }
}