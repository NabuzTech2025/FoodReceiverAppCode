class EditGroupItemResponseModel {
  int? id;
  int? toppingId;
  int? toppingGroupId;
  int? displayOrder;

  EditGroupItemResponseModel(
      {this.id, this.toppingId, this.toppingGroupId, this.displayOrder});

  EditGroupItemResponseModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    toppingId = json['topping_id'];
    toppingGroupId = json['topping_group_id'];
    displayOrder = json['display_order'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['topping_id'] = this.toppingId;
    data['topping_group_id'] = this.toppingGroupId;
    data['display_order'] = this.displayOrder;
    return data;
  }
}