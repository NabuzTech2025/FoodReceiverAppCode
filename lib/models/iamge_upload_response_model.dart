class image_upload_response_model {
  String? filename;
  String? url;

  image_upload_response_model({this.filename, this.url});

  image_upload_response_model.fromJson(Map<String, dynamic> json) {
    filename = json['filename'];
    url = json['url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['filename'] = this.filename;
    data['url'] = this.url;
    return data;
  }
}
