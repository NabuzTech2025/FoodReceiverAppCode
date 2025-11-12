
class Store {
  String? name;
  String? address;
  String? country;
  int? code;
  String? mess;


  Store({
    this.name,
    this.address,
    this.country,
  });


  Store.withError({
    int? code,
    String? mess,
  })  : code = code,
        mess = mess;

  factory Store.fromJson(Map<String, dynamic> json) => Store(
    name: json["name"],
    address: json["address"],
    country: json["country"],

  );
  Map<String, dynamic> toJson() => {
    "name": name,
    "address": address,
    "country": country,

  };


}
