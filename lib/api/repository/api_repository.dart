import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:food_app/models/Store.dart';
import 'package:food_app/models/add_tax_response_mode.dart';
import 'package:food_app/models/driver/driver_register_model.dart';
import 'package:food_app/models/reservation/edit_reservation_details_response_model.dart';
import 'package:food_app/models/reservation/get_user_reservation_details.dart';
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
import '../../models/add-store_postcode_response_model.dart';
import '../../models/add_new_group_item_response_model.dart';
import '../../models/add_new_product_category_response_model.dart';
import '../../models/add_new_product_group_response_model.dart';
import '../../models/add_new_product_response_model.dart';
import '../../models/add_new_store_timing_response_model.dart';
import '../../models/add_new_store_topping_response_model.dart';
import '../../models/add_new_topping_group_response_model.dart';
import '../../models/discount_change_response_model.dart';
import '../../models/driver/get_deliver_driver_response_model.dart';
import '../../models/edit_existing_product_category_response_model.dart';
import '../../models/edit_group_item_response_model.dart';
import '../../models/edit_postcode_response_model.dart';
import '../../models/edit_product_group_response_model.dart';
import '../../models/edit_store_product_response_model.dart';
import '../../models/edit_store_toppings_response_model.dart';
import '../../models/edit_tax_response_model.dart';
import '../../models/edit_topping_group_response_model.dart';
import '../../models/get_added_tax_response_model.dart';
import '../../models/get_discount_percentage_response_model.dart';
import '../../models/get_group_item_response_model.dart';
import '../../models/get_product_category_list_response_model.dart';
import '../../models/get_product_group_response_model.dart';
import '../../models/get_store_postcode_response_model.dart';
import '../../models/get_store_products_response_model.dart';
import '../../models/get_store_timing_response_model.dart';
import '../../models/get_toppings_groups_response_model.dart';
import '../../models/get_toppings_response_model.dart';
import '../../models/order_history_response_model.dart';
import '../../models/order_model.dart';
import '../../models/print_order_without_ip.dart';
import '../../models/reservation/accept_decline_reservation_response_model.dart';
import '../../models/reservation/add_new_reservation_response_model.dart';
import '../../models/reservation/get_history_reservation.dart';
import '../../models/reservation/get_reservation_table_full_details.dart';
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

  //For Getting Specific Store Driver
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

  //For getting Order LIst History For Specific Date
  Future<List<orderHistoryResponseModel>> orderHistory(dynamic body) async {
    httpClient.baseUrl = Api.baseUrl;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    var res = await post(
      'orders/store/filter',
      body,
      headers: {
        'accept': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
    );

    print("response is ${res.statusCode}");

    if (res.statusCode == 200) {
      print("order History Response is : ${res.statusCode.toString()}");
      print("Order History Response Body is : ${res.body}");

      // Parse the response body as a list
      List<dynamic> jsonList = res.body;
      List<orderHistoryResponseModel> orders = [];

      for (var json in jsonList) {
        orders.add(orderHistoryResponseModel.fromJson(json));
      }

      return orders;
    } else {
      throw Exception("Failed to load order history");
    }
  }

  //For Print Order Details Without Ip
  Future<printOrderWithoutIp> printWithoutIp(dynamic body) async {
    httpClient.baseUrl = Api.baseUrl ;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");
    var res = await post('orders/printorder', body, headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",},
    );
    print("response is ${res.statusCode}");
    if (res.statusCode == 200) {
      print("Print Without Ip Response is : ${res.statusCode.toString()}");
      print("Print Without Ip Response Body  is : ${res.body}");
      return printOrderWithoutIp.fromJson(res.body);
    } else {
      throw Exception(Error());
    }
  }

  //For Changing Discount Percentage
  Future<ChangeDiscountPercentageResponseModel> changeDiscount(dynamic body,String id ) async {
    httpClient.baseUrl = Api.baseUrl ;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");
    var res = await put(
      'discounts/$id', body, headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    },
    );
    print("response is ${res.statusCode}");
    if (res.statusCode == 200) {
      print("Discount Change Response is : ${res.statusCode.toString()}");
      print("Discount Change Response Body  is : ${res.body}");
      return ChangeDiscountPercentageResponseModel.fromJson(res.body);
    } else {
      throw Exception(Error());
    }
  }

  // For Getting Discount Percentage
  Future<List<GetDiscountPercentageResponseModel>> getDiscountPercentage(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('discounts/$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting Discount response is :${res.statusCode.toString()}");

      // Parse the response as a List
      List<dynamic> jsonList = res.body;
      return jsonList.map((json) => GetDiscountPercentageResponseModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load discounts: ${res.statusCode}');
    }
  }

  // For Adding New Store Timing
  Future<AddNewStoreTimingResponseModel> addStoreTiming(dynamic body, String storeId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      // Validate access token
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      // Make the API call
      var res = await post(
        'store-hours/store/$storeId',
        body,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Add Store response is ${res.statusCode}");
      print("Add Store Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add Store Timing Response is : ${res.statusCode.toString()}");
        return AddNewStoreTimingResponseModel.fromJson(res.body);
      } else if (res.statusCode == 400) {
        // Bad request - invalid data
        print("Bad Request: ${res.body}");
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        // Unauthorized - token might be expired
        print("Unauthorized: Token might be expired");
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        // Forbidden - insufficient permissions
        print("Forbidden: Insufficient permissions");
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        // Not found - store doesn't exist
        print("Store not found");
        throw Exception('Store with ID $storeId not found.');
      } else if (res.statusCode == 500) {
        // Server error
        print("Internal Server Error: ${res.body}");
        throw Exception('Server error occurred. Please try again later.');
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  // For Getting Store Timing
  Future<List<GetStoreTimingResponseModel>> getStoreTiming(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('store-hours/store/$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting Store Timing response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList.map((json) => GetStoreTimingResponseModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load Store timing: ${res.statusCode}');
    }
  }

  //For Deleting Store Timing
  Future<bool> deleteStoreTiming(int timingId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;
      var res = await delete("store-hours/$timingId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      return false;
    }
  }

  // For Getting Taxes OF Store
  Future<List<getAddedtaxResponseModel>> getStoreTax(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('taxes/$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting Store taxes response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList.map((json) => getAddedtaxResponseModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load Store taxes: ${res.statusCode}');
    }
  }

  //For Adding New Tax To store
  Future<AddTaxResponseModel> addStoreTaxes(dynamic body,) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      // Validate access token
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'taxes/', body, headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Add Store Tax response is ${res.statusCode}");
      print("Add Store Tax Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add Store Tax Response is : ${res.statusCode.toString()}");
        return AddTaxResponseModel.fromJson(res.body);
      } else if (res.statusCode == 400) {
        // Bad request - invalid data
        print("Bad Request: ${res.body}");
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        // Unauthorized - token might be expired
        print("Unauthorized: Token might be expired");
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        // Forbidden - insufficient permissions
        print("Forbidden: Insufficient permissions");
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        // Not found - store doesn't exist
        print("Store not found");
        throw Exception('Store with ID not found.');
      } else if (res.statusCode == 500) {
        // Server error
        print("Internal Server Error: ${res.body}");
        throw Exception('Server error occurred. Please try again later.');
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For editing New Tax To store
  Future<editTaxResponseModel> editStoreTaxes(dynamic body,String taxId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      // Validate access token
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'taxes/$taxId', body, headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("EDIT Store Tax response is ${res.statusCode}");
      print("EDIT Store Tax Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT Store Tax Response is : ${res.statusCode.toString()}");
        return editTaxResponseModel.fromJson(res.body);
      } else if (res.statusCode == 400) {
        // Bad request - invalid data
        print("Bad Request: ${res.body}");
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        // Unauthorized - token might be expired
        print("Unauthorized: Token might be expired");
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        // Forbidden - insufficient permissions
        print("Forbidden: Insufficient permissions");
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        // Not found - store doesn't exist
        print("Store not found");
        throw Exception('Store with ID not found.');
      } else if (res.statusCode == 500) {
        // Server error
        print("Internal Server Error: ${res.body}");
        throw Exception('Server error occurred. Please try again later.');
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  // For Deleting Store Tax
  Future<bool> deleteStoreTax(int taxId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;
      var res = await delete("taxes/$taxId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else if (res.statusCode == 400) {
        String errorBody = res.body.toString();
        print('Delete API Error: ${res.statusCode} - $errorBody');
        throw Exception('400_ERROR: $errorBody');
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false; // Return false instead of throwing exception for other errors
      }
    } catch (e) {
      if (e.toString().contains('400_ERROR')) {
        throw e; // Re-throw 400 errors
      }
      print('Delete API Exception: $e');
      return false; // Return false for network/other errors
    }
  }

  //For Getting Product Category List
  Future<List<GetProductCategoryList>> getProductCategory(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('categories/?store_id=$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting Product Category response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList.map((json) => GetProductCategoryList.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load Product Category: ${res.statusCode}');
    }
  }

  //For adding the new product Category
  Future<AddNewProductCategoryResponseModel> addNewProductCategory(dynamic body,) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      // Validate access token
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'categories/', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );

      print("Add Store Tax response is ${res.statusCode}");
      print("Add Store Tax Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add New Product Category Response is : ${res.statusCode.toString()}");
        return AddNewProductCategoryResponseModel.fromJson(res.body);
      } else if (res.statusCode == 400) {
        // Bad request - invalid data
        print("Bad Request: ${res.body}");
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        // Unauthorized - token might be expired
        print("Unauthorized: Token might be expired");
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        // Forbidden - insufficient permissions
        print("Forbidden: Insufficient permissions");
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        // Not found - store doesn't exist
        print("Store not found");
        throw Exception('Store with ID not found.');
      } else if (res.statusCode == 500) {
        // Server error
        print("Internal Server Error: ${res.body}");
        throw Exception('Server error occurred. Please try again later.');
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Deleting The Product Categories
  Future<bool> deleteProductCategory(int productId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;
      var res = await delete("categories/$productId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      return false;
    }
  }

  // For Editing the existing product category
  Future<EditExistingProductCategoryResponseModel> editProductCategory(dynamic body,String productId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      // Validate access token
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'categories/$productId', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );

      print("EDIT Product category response is ${res.statusCode}");
      print("EDIT  Product category Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT Product category Response is : ${res.statusCode.toString()}");
        return EditExistingProductCategoryResponseModel.fromJson(res.body);
      } else if (res.statusCode == 400) {
        // Bad request - invalid data
        print("Bad Request: ${res.body}");
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        // Unauthorized - token might be expired
        print("Unauthorized: Token might be expired");
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        // Forbidden - insufficient permissions
        print("Forbidden: Insufficient permissions");
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        // Not found - store doesn't exist
        print("Store not found");
        throw Exception('Store with ID not found.');
      } else if (res.statusCode == 500) {
        // Server error
        print("Internal Server Error: ${res.body}");
        throw Exception('Server error occurred. Please try again later.');
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  // For Getting Reservation Details
  Future<List<GetUserReservationDetailsResponseModel>> getReservationDetailsList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('reservations/', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    print("API Response Status Code: ${res.statusCode}");
    print("API Response Body: ${res.body}");

    if (res.statusCode == 200) {
      List<GetUserReservationDetailsResponseModel> reservations = [];
      var jsonData = res.body;

      if (jsonData is List) {
        for (var item in jsonData) {
          reservations.add(GetUserReservationDetailsResponseModel.fromJson(item));
        }
      }
      return reservations;
    } else {
      throw Exception("Failed to load reservation details. Status code: ${res.statusCode}");
    }
  }

  // For Getting New Reservation
  Future<GetUserReservationDetailsResponseModel> getNewReservationData(String bearer, int id) async {
    String url = Api.baseUrl + ApiEndPoints.getReservation + id.toString();
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

        return GetUserReservationDetailsResponseModel.fromJson(jsonData); // ✅ Parse single order object
      } else {
        return GetUserReservationDetailsResponseModel.withError(
          code: response?.statusCode ?? 500,
          mess: "Unexpected response format",
        );
      }
    } catch (e) {
      return GetUserReservationDetailsResponseModel.withError(
        code: 500,
        mess: e.toString(),
      );
    }
  }

  //for accepting and declining the reservation
  Future<GetOrderStatusResponseModel> acceptDeclineReservation(dynamic body,String reservationId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      var res = await put('reservations/$reservationId', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );

      print("Reservation response is ${res.statusCode}");
      print("Reservation response is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Reservation Response is : ${res.statusCode.toString()}");
        return GetOrderStatusResponseModel.fromJson(res.body);
      } else if (res.statusCode == 400) {
        // Bad request - invalid data
        print("Bad Request: ${res.body}");
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        // Unauthorized - token might be expired
        print("Unauthorized: Token might be expired");
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        // Forbidden - insufficient permissions
        print("Forbidden: Insufficient permissions");
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        // Not found - store doesn't exist
        print("Store not found");
        throw Exception('Store with ID not found.');
      } else if (res.statusCode == 500) {
        // Server error
        print("Internal Server Error: ${res.body}");
        throw Exception('Server error occurred. Please try again later.');
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Status error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Reservation table Full details
  Future<GetOrderDetailsResponseModel> getReservationFullDetails(String reservationId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");
    httpClient.baseUrl = Api.baseUrl;
    var res = await get('reservations/$reservationId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });
    if (res.statusCode == 200) {
      print("Reservation Details response is :${res.statusCode.toString()}");
      return GetOrderDetailsResponseModel.fromJson(res.body);
    } else {
      throw Exception(Error());
    }
  }

  // for Getting reservation History
  Future<List<GetHistoryReservationResponseModel>> reservationHistory(dynamic body) async {
    httpClient.baseUrl = Api.baseUrl;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    var res = await post(
      'reservations/store/filter',
      body,
      headers: {
        'accept': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
    );

    print("response is ${res.statusCode}");

    if (res.statusCode == 200) {
      print("order History Response is : ${res.statusCode.toString()}");
      print("Order History Response Body is : ${res.body}");

      // Parse the response body as a list
      List<dynamic> jsonList = res.body;
      List<GetHistoryReservationResponseModel> reservation = [];

      for (var json in jsonList) {
        reservation.add(GetHistoryReservationResponseModel.fromJson(json));
      }

      return reservation;
    } else {
      throw Exception("Failed to load order history");
    }
  }

  //For Editing reservation details
  Future<EditReservationDetailsResponseModel> editReservationDetails(dynamic body,String reservationId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      // Validate access token
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'reservations/$reservationId', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );

      print("EDIT Store Tax response is ${res.statusCode}");
      print("EDIT Store Tax Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT Reservation Response is : ${res.statusCode.toString()}");
        return EditReservationDetailsResponseModel.fromJson(res.body);
      } else if (res.statusCode == 400) {
        // Bad request - invalid data
        print("Bad Request: ${res.body}");
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        // Unauthorized - token might be expired
        print("Unauthorized: Token might be expired");
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        // Forbidden - insufficient permissions
        print("Forbidden: Insufficient permissions");
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        // Not found - store doesn't exist
        print("Store not found");
        throw Exception('Store with ID not found.');
      } else if (res.statusCode == 500) {
        // Server error
        print("Internal Server Error: ${res.body}");
        throw Exception('Server error occurred. Please try again later.');
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Adding New Reservation
  Future<AddNewReservationResponseModel> addReservation(dynamic body,) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");

      // Validate access token
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'reservations/guest', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );

      print("Add Reservation response is ${res.statusCode}");
      print("Add Reservation Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add Reservation Response is : ${res.statusCode.toString()}");
        return AddNewReservationResponseModel.fromJson(res.body);
      } else if (res.statusCode == 400) {
        // Bad request - invalid data
        print("Bad Request: ${res.body}");
        throw Exception('Invalid request data: ${res.body}');
      } else if (res.statusCode == 401) {
        // Unauthorized - token might be expired
        print("Unauthorized: Token might be expired");
        throw Exception('Authentication failed. Please login again.');
      } else if (res.statusCode == 403) {
        // Forbidden - insufficient permissions
        print("Forbidden: Insufficient permissions");
        throw Exception('You do not have permission to perform this action.');
      } else if (res.statusCode == 404) {
        // Not found - store doesn't exist
        print("Store not found");
        throw Exception('Store with ID not found.');
      } else if (res.statusCode == 500) {
        // Server error
        print("Internal Server Error: ${res.body}");
        throw Exception('Server error occurred. Please try again later.');
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Getting products Of Specific Store
  Future<List<GetStoreProducts>> getProducts(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('products/?store_id=$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting Product of Store response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList.map((json) => GetStoreProducts.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load Product of Store: ${res.statusCode}');
    }
  }

  //For Add New Products
  Future<AddNewProductResponseModel> addNewProduct(dynamic body,) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'products/', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );

      print("Add Product response is ${res.statusCode}");
      print("Add Product Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add Product Response is : ${res.statusCode.toString()}");
        return AddNewProductResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Editing the Existing Products
  Future<EditStoreProductResponseModel> editProducts(dynamic body,String productId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'products/$productId', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );

      print("EDIT Store Product response is ${res.statusCode}");
      print("EDIT Store Product Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT Product Response is : ${res.statusCode.toString()}");
        return EditStoreProductResponseModel.fromJson(res.body);
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Deleting Product
  Future<bool> deleteProduct(int productId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;
      var res = await delete("products/$productId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      return false;
    }
  }

  //For Getting Toppings
  Future<List<GetToppingsResponseModel>> getToppings(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('toppings/?store_id=$storeId', headers: {
      'accept': 'application/json',
      //'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting Toppings of Store response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList.map((json) => GetToppingsResponseModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load Toppings of Store: ${res.statusCode}');
    }
  }

  //For Add New Toppings
  Future<AddNewStoreToppingsResponseModel> addNewToppings(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'toppings/', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );

      print("Add Toppings response is ${res.statusCode}");
      print("Add Toppings Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add Toppings Response is : ${res.statusCode.toString()}");
        return AddNewStoreToppingsResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Editing Existing Toppings
  Future<EditStoreToppingsResponseModel> editToppings(dynamic body,String toppingsId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'toppings/$toppingsId', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );

      print("EDIT Store Toppings response is ${res.statusCode}");
      print("EDIT Store Toppings Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT Toppings Response is : ${res.statusCode.toString()}");
        return EditStoreToppingsResponseModel.fromJson(res.body);
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Deleting Toppings
  Future<bool> deleteToppings(String toppingId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;
      var res = await delete("toppings/$toppingId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      return false;
    }
  }

  //For Getting Postcode
  Future<List<GetStorePostCodesResponseModel>> getPostCode(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('postcodes/store/$storeId', headers: {
      'accept': 'application/json',
      //'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting Postcode of Store response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList.map((json) => GetStorePostCodesResponseModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load Postcode of Store: ${res.statusCode}');
    }
  }

  //For Add New PostCode
  Future<List<AddStorePostCodesResponseModel>> addNewPostcode(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }
      var res = await post(
        'postcodes/', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );
      print("Add PostCode response is ${res.statusCode}");
      print("Add PostCode Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add PostCode Response is : ${res.statusCode.toString()}");
        List<dynamic> jsonList = res.body;
        return jsonList.map((json) => AddStorePostCodesResponseModel.fromJson(json)).toList();
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");

      // Re-throw the exception with more context
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Editing PostCode
  Future<List<EditStorePostCodesResponseModel>> editPostcode(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'postcodes/', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );

      print("EDIT Store PostCode response is ${res.statusCode}");
      print("EDIT Store Postcode Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT PostCode Response is : ${res.statusCode.toString()}");
        List<dynamic> jsonList = res.body;
        return jsonList.map((json) => EditStorePostCodesResponseModel.fromJson(json)).toList();
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Deleting PostCode
  Future<bool> deletePostCode(int postcodeId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;
      var res = await delete("postcodes/$postcodeId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      return false;
    }
  }

  //For Getting Toppings Group
  Future<List<GetToppingsGroupResponseModel>> getToppingGroups(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('toppings/groups?store_id=$storeId', headers: {
      'accept': 'application/json',
      //'Authorization': "Bearer $accessToken",
    });

    if (res.statusCode == 200) {
      print("Getting Toppings of Store response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList.map((json) => GetToppingsGroupResponseModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load Toppings of Store: ${res.statusCode}');
    }
  }

  //For Add New Topping Group
  Future<AddToppingsGroupResponseModel> addToppingGroup(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'toppings/groups', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );

      print("Add Topping Group response is ${res.statusCode}");
      print("Add Topping Group Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add Topping Group Response is : ${res.statusCode.toString()}");
        return AddToppingsGroupResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  // For Editing Topping Group
  Future<EditToppingsGroupResponseModel> editToppingGroup(dynamic body,String groupId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'toppings/groups/$groupId', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );

      print("EDIT Store Topping Group response is ${res.statusCode}");
      print("EDIT Store Topping Group Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT Topping Group Response is : ${res.statusCode.toString()}");
        return EditToppingsGroupResponseModel.fromJson(res.body);
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Delete Topping Group
  Future<bool> deleteToppingGroup(String groupId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;
      var res = await delete("toppings/groups/$groupId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      return false;
    }
  }

  // For Getting Group Items
  Future<List<GetGroupItemResponseModel>> getGroupItems(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('toppings/group-items?store_id=$storeId', headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });
    if (res.statusCode == 200) {
      print("Getting Group items response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList.map((json) => GetGroupItemResponseModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load Group items : ${res.statusCode}');
    }
  }

  //For Add New Group Item
  Future<AddGroupItemResponseModel> addGroupItem(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'toppings/group-items', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );

      print("Add  Group Item response is ${res.statusCode}");
      print("Add  Group Item Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add  Group Item Response is : ${res.statusCode.toString()}");
        return AddGroupItemResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  // For Edit Group Items
  Future<EditGroupItemResponseModel> editGroupItem(dynamic body,String groupItemId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'toppings/group-items/$groupItemId', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );

      print("EDIT Group Item response is ${res.statusCode}");
      print("EDIT Group Item Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT Group Item Response is : ${res.statusCode.toString()}");
        return EditGroupItemResponseModel.fromJson(res.body);
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  // For Deleting the group item
  Future<bool> deleteGroupItem(String groupItemId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;
      var res = await delete("toppings/group-items/$groupItemId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );
      if (res.statusCode == 200 || res.statusCode == 204) {
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      return false;
    }
  }

  //For Getting Product Groups
  Future<List<GetProductGroupResponseModel>> getProductGroup(String storeId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString(valueShared_BEARER_KEY);
    print("User Access Token Value is : $accessToken");

    httpClient.baseUrl = Api.baseUrl;
    var res = await get('toppings/product-groups?store_id=$storeId',
        headers: {
      'accept': 'application/json',
      'Authorization': "Bearer $accessToken",
    });
    if (res.statusCode == 200) {
      print("Getting Product Group response is :${res.statusCode.toString()}");
      List<dynamic> jsonList = res.body;
      return jsonList.map((json) => GetProductGroupResponseModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load Product Group : ${res.statusCode}');
    }
  }

  //For Add New Product Group
  Future<AddNewProductGroupResponseModel> addProductGroup(dynamic body) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await post(
        'toppings/product-groups', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );

      print("Add  ProductGroup response is ${res.statusCode}");
      print("Add  ProductGroup Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("Add  ProductGroup Response is : ${res.statusCode.toString()}");
        return AddNewProductGroupResponseModel.fromJson(res.body);
      } else {
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("Adding error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  //For Editing Product Group
  Future<EditProductGroupResponseModel> editProductGroup(dynamic body,String productGroupId) async {
    try {
      httpClient.baseUrl = Api.baseUrl;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('Access token is null or empty');
      }

      var res = await put(
        'toppings/product-groups/$productGroupId', body, headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': "Bearer $accessToken",
      },
      );

      print("EDIT Product Group response is ${res.statusCode}");
      print("EDIT Product Group Response Body is : ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        print("EDIT Product Group Response is : ${res.statusCode.toString()}");
        return EditProductGroupResponseModel.fromJson(res.body);
      } else {
        // Other errors
        print("Unexpected error: ${res.statusCode} - ${res.body}");
        throw Exception('Request failed with status code: ${res.statusCode}');
      }
    } catch (e) {
      print("EDIT error: $e");
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('An unexpected error occurred: $e');
      }
    }
  }

  // For Delete Product Group
  Future<bool> deleteProductGroup(String productGroupId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString(valueShared_BEARER_KEY);
      print("User Access Token Value is : $accessToken");
      httpClient.baseUrl = Api.baseUrl;

      var res = await delete(
        "toppings/product-groups/$productGroupId",
        headers: {
          'Content-Type': 'application/json',
          'Authorization': "Bearer $accessToken",
        },
      );

      print("Delete Product Group Response Status: ${res.statusCode}");

      // 204 means success but no content returned
      if (res.statusCode == 200 || res.statusCode == 204) {
        print("Product Group deleted successfully");
        return true;
      } else {
        print('Delete API Error: ${res.statusCode} - ${res.body}');
        return false;
      }
    } catch (e) {
      print('Delete API Exception: $e');
      // Even if GetX throws error on 204, check if it's actually successful
      if (e.toString().contains('Cannot decode')) {
        print("Delete successful but response was empty (204)");
        return true;
      }
      return false;
    }
  }

}