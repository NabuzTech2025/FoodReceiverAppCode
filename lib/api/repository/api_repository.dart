import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:food_app/models/Store.dart';
import 'package:food_app/models/driver/driver_register_model.dart';
import 'package:food_app/models/today_report.dart';
import 'package:get/get.dart' hide FormData;

import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/constant.dart';
import '../../models/DailySalesReport.dart' hide TaxBreakdown, PaymentMethods, ApprovalStatuses;
import '../../models/Logout.dart';
import '../../models/PrinterSetting.dart';
import '../../models/StoreDetail.dart';
import '../../models/StoreSetting.dart';
import '../../models/UserMe.dart';
import '../../models/driver/get_deliver_driver_response_model.dart';
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

}

class CallService extends GetConnect {

  //get live reports for today sales
  Future<GetTodayReport> getLiveSaleData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);

      print("🔑 User Access Token Value is: $accessToken");

      if (accessToken == null || accessToken.isEmpty) {
        print("❌ Access token is null or empty");
        throw Exception("Access token not found");
      }

      httpClient.baseUrl = Api.baseUrl;
      print("🌐 Making API call to: ${Api.baseUrl}/reports/today");

      var res = await get('reports/today',
        headers: {
          'accept': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("📡 API Response Status Code: ${res.statusCode}");
      print("📄 API Response Body: ${res.body}");

      if (res.statusCode == 200) {
        print("✅ Today Report Response Is Success: ${res.statusCode}");

        if (res.body == null || res.body.toString().trim().isEmpty) {
          print("❌ Response body is empty despite 200 status");
          return _createEmptyReport();
        }

        try {
          final parsedResponse = GetTodayReport.fromJson(res.body);
          print("✅ Successfully parsed response");
          return parsedResponse;
        } catch (parseError) {
          print("❌ JSON Parsing Error: $parseError");
          return _createEmptyReport();
        }

      } else if (res.statusCode == 204) {
        // ✅ Handle 204 No Content - this is normal for no data
        print("ℹ️ No Content (204) - No sales data available for today");
        print("ℹ️ This is normal if there are no orders yet today");

        return _createEmptyReport();

      } else if (res.statusCode == 401) {
        print("❌ Unauthorized - Token may be expired");
        throw Exception("Unauthorized: Please login again");

      } else if (res.statusCode == 404) {
        print("❌ API endpoint not found");
        throw Exception("API endpoint not found");

      } else if (res.statusCode == 500) {
        print("❌ Server error");
        throw Exception("Server error: ${res.statusCode}");

      } else {
        print("❌ API call failed with status: ${res.statusCode}");
        print("❌ Response body: ${res.body}");
        throw Exception("API call failed with status ${res.statusCode}: ${res.body}");
      }

    } catch (e) {
      print("❌ Exception in getLiveSaleData: $e");

      // ✅ For 204 responses, return empty data instead of throwing error
      if (e.toString().contains('204')) {
        print("ℹ️ Returning empty report for 204 response");
        return _createEmptyReport();
      }

      rethrow;
    }
  }

  GetTodayReport _createEmptyReport() {
    print("📊 Creating empty report with zero values");

    return GetTodayReport(
      totalSales: 0.0,
      totalOrders: 0,
      cashTotal: 0.0,
      onlineTotal: 0.0,
      discountTotal: 0.0,
      deliveryTotal: 0.0,
      totalTax: 0.0,
      netTotal: 0.0,
      totalSalesDelivery: 0.0,
      taxBreakdown: TaxBreakdown(d7: 0.0, d19: 0.0),
      paymentMethods: PaymentMethods(cash: 0),
      orderTypes: OrderTypes(delivery: 0, pickup: 0, dineIn: 0),
      approvalStatuses: ApprovalStatuses(pending: 0, accepted: 0, declined: 0),
      topItems: [],
      byCategory: null,
    );
  }
  //Driver Section

  //1.) Create Driver
  Future<DriverRegisterModel> registerDriver(dynamic body) async {
    httpClient.baseUrl = Api.baseUrl ;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");
    var res = await post(
      'delivery/register-driver/', body, headers: {
        'accept': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
    );
    print("response is ${res.statusCode}");
    if (res.statusCode == 200) {
      print("Driver Register Response is : ${res.statusCode.toString()}");
      print("Driver Register Response Body  is : ${res.body}");
      return DriverRegisterModel.fromJson(res.body);
    } else {
      throw Exception(Error());
    }
  }



  Future<GetSpecificStoreDeliveryDriverResponseModel> getDeliveryDriver(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('delivery/drivers/$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });
    if (res.statusCode == 200) {
      print("Delivery Driver Details response is :${res.statusCode.toString()}");
      return GetSpecificStoreDeliveryDriverResponseModel.fromJson(res.body);
    } else {
      throw Exception(Error());
    }
  }




}