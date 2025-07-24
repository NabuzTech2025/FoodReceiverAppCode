import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:food_app/models/Store.dart';
import 'package:food_app/models/driver/driver_register_model.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/constant.dart';
import '../../models/DailySalesReport.dart';
import '../../models/Logout.dart';
import '../../models/PrinterSetting.dart';
import '../../models/StoreDetail.dart';
import '../../models/StoreSetting.dart';
import '../../models/UserMe.dart';
import '../../models/order_model.dart';
import '../api.dart';
import '../api_end_points.dart';
import '../api_params.dart';
import '../api_utils.dart';
import '../responses/userLogin_h.dart';
import 'base_repository.dart';

final title = "ApiRepo";

class ApiRepo {
  Future<UserLoginH> loginApi(String email, String password, String deviceToken) async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      print("Error Internet connectivity");
      return UserLoginH.withError(
          code: CODE_NO_INTERNET, mess: apiUtils.getNetworkError());
    }

    String url = Api.baseUrl + ApiEndPoints.login;
    Map<String, dynamic> loginData = {
      'username': email,
      'password': password,
      'device_token': deviceToken,
    };

    FormData formData = FormData.fromMap(loginData);

    try {
      final response = await apiUtils.post(url: url, data: formData);
      print("REsponseData " + response.toString());
      if (response != null) {
        return UserLoginH.fromJson(response.data);
        /*  if (response.data['code'] == 0) {
          return UserLoginH.fromJson(response.data);
        } else {
          return UserLoginH.withError(
              code: CODE_RESPONSE_NULL, mess: response.data['message']);
        }*/
      }

      //return null;
      return UserLoginH.withError(code: CODE_RESPONSE_NULL, mess: "");
    } catch (e) {
      return UserLoginH.withError(
          code: CODE_ERROR, mess: apiUtils.handleError(e));
    }
  }

  Future<UserLoginH> resetPasswordApi(String password, String cPassword) async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      print("Error Internet connectivity");
      return UserLoginH.withError(
          code: CODE_NO_INTERNET, mess: apiUtils.getNetworkError());
    }

    String url = Api.baseUrl + ApiEndPoints.resetPassword;
    Map<String, dynamic> loginData = {
      'password': password,
      'confirmpassword': cPassword,
    };

    FormData formData = FormData.fromMap(loginData);

    try {
      final response = await apiUtils.post(url: url, data: formData);
      print("REsponseData " + response.toString());
      if (response != null) {
        return UserLoginH.fromJson(response.data);
        /*  if (response.data['code'] == 0) {
          return UserLoginH.fromJson(response.data);
        } else {
          return UserLoginH.withError(
              code: CODE_RESPONSE_NULL, mess: response.data['message']);
        }*/
      }

      //return null;
      return UserLoginH.withError(code: CODE_RESPONSE_NULL, mess: "");
    } catch (e) {
      return UserLoginH.withError(
          code: CODE_ERROR, mess: apiUtils.handleError(e));
    }
  }

  Future<List<Order>> orderGetApi(String bearer) async {
    String url = Api.baseUrl + ApiEndPoints.getOrders;
    try {
      final response = await apiUtils.get(
        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data is List) {
        return (response.data as List)
            .map((json) => Order.fromJson(json))
            .toList();
      } else {
        return [
          Order.withError(
            code: response?.statusCode ?? 500,
            mess: "Unexpected response format",
          )
        ];
      }
    } catch (e) {
      return [
        Order.withError(
          code: 500,
          mess: e.toString(),
        )
      ];
    }
  }

  Future<List<Order>> orderGetApiFilter(String bearer, Map<String, dynamic> data) async {
    String url = Api.baseUrl + ApiEndPoints.getOrderFilter;

    try {
      final response = await apiUtils.post(
        url: url,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data is List) {
        return (response.data as List)
            .map((json) => Order.fromJson(json))
            .toList();
      } else {
        return [
          Order.withError(
            code: response?.statusCode ?? 500,
            mess: "Unexpected response format",
          )
        ];
      }
    } catch (e) {
      return [
        Order.withError(
          code: 500,
          mess: e.toString(),
        )
      ];
    }
  }

  Future<StoreDetail> getStoreID(String? bearer) async {
    String url = Api.baseUrl + ApiEndPoints.getStoreDetail;

    try {
      final response = await apiUtils.post(
        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response != null) {
        final jsonData = response.data;
        return StoreDetail.fromJson(jsonData);
        ;
      } else {
        return StoreDetail.withError(
          code: response?.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      return StoreDetail.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }

  Future<List<DailySalesReport>> reportGetApi(String bearer) async {
    String url = Api.baseUrl + ApiEndPoints.getReports;
    try {
      final response = await apiUtils.get(
        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response != null &&
          response.statusCode == 200 &&
          response.data is List) {
        return (response.data as List)
            .map((json) => DailySalesReport.fromJson(json))
            .toList();
      } else {
        return [
          DailySalesReport.withError(
            code: response?.statusCode ?? 500,
            mess: "Unexpected response format",
          )
        ];
      }
    } catch (e) {
      return [
        DailySalesReport.withError(
          code: 500,
          mess: e.toString(),
        )
      ];
    }
  }

  Future<Order> orderAcceptDecline(String bearer, Map<String, dynamic> jsonData, int? id) async {
    //print("JsonDatsss "+jsonData.toString());

    String url =
        Api.baseUrl + ApiEndPoints.getOrderStatus + "/" + id.toString();
    try {
      /*final response = await apiUtils.post(
        url: url,
        data: jsonData ,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );*/
      final response = await Dio().put(
        url,
        data: jsonData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          followRedirects: false,
          // by default it's true for GET, false for POST
          validateStatus: (status) => status! < 500, // allow 307 to be captured
        ),
      );
      print("UrlData " + url);
      print("First call " + response.toString());
      if (response.statusCode == 307) {
        print("Called 307");
        final redirectedUrl = response.headers.value('location');
        if (redirectedUrl != null) {
          print("Called 307 1 " + redirectedUrl);
          final redirectedResponse = await Dio().put(
            redirectedUrl,
            data: jsonData,
            options: Options(
              headers: {
                'Authorization': 'Bearer $bearer',
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );

          print('Redirected response: ${redirectedResponse.data}');
        }
      } else {
        print('Response: ${response.data}');
      }

      if (response != null && response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        return Order.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return Order.withError(
          code: response?.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      print("GetTheREsponse Error " + e.toString());
      return Order.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }

  Future<Order> getNewOrderData(String bearer, int id) async {
    String url = Api.baseUrl + ApiEndPoints.getOrders + id.toString();
    try {
      final response = await apiUtils.get(

        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response != null && response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        print("🚀 API Order Response: ${response.data}");

        return Order.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return Order.withError(
          code: response?.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      return Order.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }

  Future<UserMe> getUserMe(String? bearer) async {
    String url = Api.baseUrl + ApiEndPoints.getUserMe;
    try {
      final response = await apiUtils.get(
        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response != null && response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        return UserMe.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return UserMe.withError(
          code: response?.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      return UserMe.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }


  Future<Logout> logoutAPi(String? bearer) async {
    String url = Api.baseUrl + ApiEndPoints.logoutApi;
    try {
      final response = await apiUtils.post(
        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response != null && response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        return Logout.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return Logout.withError(
          code: response?.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      return Logout.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }

  Future<StoreSetting> getStoreSetting(String? bearer,String storeID) async {
    String url = Api.baseUrl + ApiEndPoints.getStoreSetting + storeID;
    try {
      final response = await apiUtils.get(
        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response != null && response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        return StoreSetting.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return StoreSetting.withError(
          code: response?.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      return StoreSetting.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }

  Future<StoreSetting> storeSettingPost(String bearer, Map<String, dynamic> jsonData) async {


    String url =
        Api.baseUrl + ApiEndPoints.getStoreSetting;
    try {

      final response = await Dio().post(
        url,
        data: jsonData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          followRedirects: false,
          // by default it's true for GET, false for POST
          validateStatus: (status) => status! < 500, // allow 307 to be captured
        ),
      );
      print("UrlData " + url);
      print("First call " + response.toString());
      if (response.statusCode == 307) {
        print("Called 307");
        final redirectedUrl = response.headers.value('location');
        if (redirectedUrl != null) {
          print("Called 307 1 " + redirectedUrl);
          final redirectedResponse = await Dio().put(
            redirectedUrl,
            data: jsonData,
            options: Options(
              headers: {
                'Authorization': 'Bearer $bearer',
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );

          print('Redirected response: ${redirectedResponse.data}');
        }
      } else {
        print('Response: ${response.data}');
      }

      if (response != null && response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        return StoreSetting.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return StoreSetting.withError(
          code: response?.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      print("GetTheREsponse Error " + e.toString());
      return StoreSetting.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }

  Future<PrinterSetting> printerSettingPost(String bearer, Map<String, dynamic> jsonData) async {


    String url =
        Api.baseUrl + ApiEndPoints.postPrinterSetting;
    try {

      final response = await Dio().post(
        url,
        data: jsonData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          followRedirects: false,
          // by default it's true for GET, false for POST
          validateStatus: (status) => status! < 500, // allow 307 to be captured
        ),
      );
      print("UrlData " + url);
      print("First call " + response.toString());
      if (response.statusCode == 307) {
        print("Called 307");
        final redirectedUrl = response.headers.value('location');
        if (redirectedUrl != null) {
          print("Called 307 1 " + redirectedUrl);
          final redirectedResponse = await Dio().put(
            redirectedUrl,
            data: jsonData,
            options: Options(
              headers: {
                'Authorization': 'Bearer $bearer',
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );

          print('Redirected response: ${redirectedResponse.data}');
        }
      } else {
        print('Response: ${response.data}');
      }

      if (response != null && response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        return PrinterSetting.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return PrinterSetting.withError(
          code: response?.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      print("GetTheREsponse Error " + e.toString());
      return PrinterSetting.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }
  Future<Store> getStoreData(String bearer, String id) async {
    String url = Api.baseUrl + ApiEndPoints.getStoreDetail + id;
    try {
      final response = await apiUtils.get(
        url: url,
        options: Options(
          headers: {
            'Authorization': 'Bearer $bearer',
            'Accept': 'application/json',
          },
        ),
      );

      if (response != null && response.statusCode == 200) {
        // Ensure the response data is a map
        final jsonData = response.data;
        return Store.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return Store.withError(
          code: response?.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      return Store.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }
//
// /*  Future<List<Order>> orderGetApi(String bearer) async {
//     final connectivityResult = await (Connectivity().checkConnectivity());
//  */ /*   if (connectivityResult == ConnectivityResult.none) {
//       print("Error Internet connectivity");
//       return Order.withError(
//           code: CODE_NO_INTERNET, mess: apiUtils.getNetworkError());
//     }*/ /*
//     String url = Api.baseUrl + ApiEndPoints.getOrders;
//     print("URlToken "+url);
//
//    // String Token="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyMiIsInNlc3Npb25faWQiOiI4MGFlN2Q2Ny03MjMwLTRjMjUtODZjOS1lN2RiZTczMjU5M2YiLCJleHAiOjE3NDY0NjIwNjR9.vxdMBFo8D7dGuVztUgzp1jhe04u6Ck6Rec_3SJpyvQA";
//     try {
//       final response = await apiUtils.get(url: url, options:  Options(
//         headers: {
//           'Authorization': 'Bearer $bearer',
//           'Accept': 'application/json',
//         },
//       ),);
//      */ /* final response = await Dio().get(
//         url,
//         options: Options(
//           headers: {
//             'Authorization': 'Bearer Token $Token',
//           },
//         ),
//       );*/ /*
//
//       print("REsponseData " + response.toString());
//       if (response != null) {
//         List<Order> orders = (response.data as List)
//             .map((json) => Order.fromJson(json))
//             .toList();
//         return orders;
//         //return Order.fromJson(response.data);
//       }
//
//       //return null;
//      // return Order.withError(code: CODE_RESPONSE_NULL, mess: "");
//     } catch (e) {
//       //return Order.withError(code: CODE_ERROR, mess: apiUtils.handleError(e));
//     }
//   }*/
// /*
//
//   Future<RegistrationResponse> registerApi(
//       String email, String name, String lastname, String password) async {
//     final connectivityResult = await (Connectivity().checkConnectivity());
//     if (connectivityResult == ConnectivityResult.none) {
//       return RegistrationResponse.withError(
//           code: CODE_NO_INTERNET, mess: apiUtils.getNetworkError());
//     }
//
//     String url = Api.baseUrlSelected + ApiEndPoints.createUser;
//     Map<String, dynamic> loginData = {
//       'email': email,
//       'firstName': name,
//       'lastName': lastname,
//       'password': password,
//     };
//
//     FormData formData = FormData.fromMap(loginData);
//
//     try {
//       final response = await apiUtils.post(url: url, data: formData);
//
//       if (response != null) {
//         //UserData userLogin=UserData.fromJson(response.data);
//         */
// /*List<ProductModel> products = List<ProductModel>.from(
//             response.data.map((x) => ProductModel.fromJson(x)));*/ /*
//
//
//         return RegistrationResponse.fromJson(response.data);
//       }
//
//       //return null;
//       return RegistrationResponse.withError(code: CODE_RESPONSE_NULL, mess: "");
//     } catch (e) {
//       return RegistrationResponse.withError(
//           code: CODE_ERROR, mess: apiUtils.handleError(e));
//     }
//   }
//
//   Future<BaseResponse> resetPassworddApi(String email) async {
//     final connectivityResult = await (Connectivity().checkConnectivity());
//     if (connectivityResult == ConnectivityResult.none) {
//       return BaseResponse.withError(
//           code: CODE_NO_INTERNET, mess: apiUtils.getNetworkError());
//     }
//
//     String url = Api.baseUrlSelected + ApiEndPoints.resetPassword;
//     Map<String, dynamic> loginData = {
//       'email': email,
//     };
//
//     FormData formData = FormData.fromMap(loginData);
//
//     try {
//       final response = await apiUtils.post(url: url, data: formData);
//
//       if (response != null) {
//         return BaseResponse.fromJson(response.data);
//       }
//
//       //return null;
//       return BaseResponse.withError(code: CODE_RESPONSE_NULL, mess: "");
//     } catch (e) {
//       return BaseResponse.withError(
//           code: CODE_ERROR, mess: apiUtils.handleError(e));
//     }
//   }
// */

// Driver
//1.) Driver Register




}
