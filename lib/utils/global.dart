// import 'package:flutter/material.dart';
// import 'package:food_app/api/repository/api_repository.dart';
// import 'package:food_app/constants/constant.dart';
// import 'package:food_app/models/Store.dart';
// import 'package:food_app/models/order_model.dart';
// import 'package:food_app/utils/log_util.dart';
// import 'package:food_app/utils/my_application.dart';
// import 'package:food_app/utils/printer_helper_english.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// Future<void> getOrdersInBackground() async {
//   try {
//     print("Global APi called from home");
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? bearerKey = prefs.getString(valueShared_BEARER_KEY);
//     String? storeID = prefs.getString(valueShared_STORE_KEY);
//     if (bearerKey == null) {
//       print("❌ Bearer key not found in SharedPreferences");
//       return;
//     }
//
//     DateTime formatted = DateTime.now();
//     String date = DateFormat('yyyy-MM-dd').format(formatted);
//
//     final Map<String, dynamic> data = {
//       "store_id": storeID,
//       "target_date": date,
//       "limit": 0,
//       "offset": 0,
//     };
//
//     final result = await ApiRepo().orderGetApiFilter(bearerKey, data);
//
//     if (result.isNotEmpty && result.first.code == null) {
//       print("✅ Background order fetch success: ${result.length} orders");
//       // Optionally: Save to Hive or another background-safe store
//       Future.delayed(Duration(seconds: 2), () {
//         app.appController.setOrders(result);
//       });
//     } else {
//       String errorMessage = result.isNotEmpty
//           ? result.first.mess ?? "Unknown error"
//           : "No data returned";
//       print("⚠️ Background fetch error: $errorMessage");
//     }
//   } catch (e) {
//     print("❌ Exception in background order fetch: $e");
//   }
// }
// //
// // Future<void> getOrdersInForegrund(BuildContext context, int orderID) async {
// //   try {
// //     bool _autoOrderAccept = false;
// //     bool _autoOrderPrint = false;
// //     SharedPreferences prefs = await SharedPreferences.getInstance();
// //     String? bearerKey = prefs.getString(valueShared_BEARER_KEY);
// //     String? storeID = prefs.getString(valueShared_STORE_KEY);
// //     if (bearerKey == null) {
// //       print("❌ Bearer key not found in SharedPreferences");
// //       return;
// //     }
// //     final result = await ApiRepo().getNewOrderData(bearerKey!, orderID);
// //     if (result != null) {
// //       app.appController.addNewOrder(result); // Wrap in a list if needed
// //       _autoOrderAccept = prefs.getBool('auto_order_accept') ?? false;
// //       _autoOrderPrint = prefs.getBool('auto_order_print') ?? false;
// //       if (_autoOrderAccept) {
// //         getOrders(bearerKey!, true, result);
// //       }
// //       if (_autoOrderPrint) {
// //         PrinterHelperEnglish.printTestFromSavedIp(
// //             context: context, order: result, store: "AutoOrder",auto: true);
// //       }
// //     } else {
// //       String errorMessage = result.mess ?? "Unknown error";
// //       showSnackbar("Error", errorMessage);
// //     }
// //   } catch (e) {
// //     showSnackbar("Api Error", "An error occurred: $e");
// //   }
// // }
//
//
// Future<void> getOrdersInForegrund(BuildContext context, int orderID) async {
//   try {
//     bool _autoOrderAccept = false;
//     bool _autoOrderPrint = false;
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? bearerKey = prefs.getString(valueShared_BEARER_KEY);
//
//     if (bearerKey == null) {
//       print("❌ Bearer key not found in SharedPreferences");
//       return;
//     }
//
//     final result = await ApiRepo().getNewOrderData(bearerKey, orderID);
//
//     if (result != null) {
//       app.appController.addNewOrder(result);
//
//       _autoOrderAccept = prefs.getBool('auto_order_accept') ?? false;
//       _autoOrderPrint = prefs.getBool('auto_order_print') ?? false;
//
//       if (_autoOrderAccept) {
//         // Step 1: Accept the order first
//         await getOrders(bearerKey, true, result);
//
//         // Step 2: Wait for 2 seconds (ensure backend updates)
//         await Future.delayed(Duration(seconds: 2));
//
//         // Step 3: Fetch the updated order after acceptance
//         final updatedOrder = await ApiRepo().getNewOrderData(bearerKey, orderID);
//
//         // Step 4: Check invoice data
//         if (_autoOrderPrint) {
//           if (updatedOrder.invoice != null &&
//               updatedOrder.invoice?.invoiceNumber != null &&
//               updatedOrder.invoice!.invoiceNumber!.isNotEmpty) {
//
//             // Step 5: Print the order (after acceptance & invoice ready)
//             PrinterHelperEnglish.printTestFromSavedIp(
//                 context: context, order: updatedOrder, store: '', auto: true);
//
//           } else {
//             print("❌ Invoice not ready after accept. Skipping print.");
//           }
//         }
//       }
//     } else {
//       String errorMessage = result.mess ?? "Unknown error";
//       showSnackbar("Error", errorMessage);
//     }
//   } catch (e) {
//     showSnackbar("Api Error", "An error occurred: $e");
//   }
// }
// //
// // Future<void> getOrders(String bearerKey, bool orderStatus, Order updatedOrder) async {
// //   Map<String, dynamic> jsonData = {
// //     "order_status": orderStatus ? 2 : 1,
// //     "approval_status": orderStatus ? 2 : 3,
// //   };
// //
// //   try {
// //     final result = await ApiRepo()
// //         .orderAcceptDecline(bearerKey, jsonData, updatedOrder.id ?? 0);
// //
// //     if (result != null) {
// //       updatedOrder = result;
// //       app.appController.updateOrder(result);
// //     } else {
// //       //showSnackbar("Error", "Failed to update order status");
// //     }
// //   } catch (e) {
// //     //showSnackbar("Api Error", "An error occurred: $e");
// //   }
// // }
// //
// Future<void> getOrders(String bearerKey, bool orderStatus, Order updatedOrder) async {
//   Map<String, dynamic> jsonData = {
//     "order_status": orderStatus ? 2 : 1,
//     "approval_status": orderStatus ? 2 : 3,
//   };
//
//   try {
//     final result = await ApiRepo().orderAcceptDecline(bearerKey, jsonData, updatedOrder.id ?? 0);
//
//     if (result != null) {
//       updatedOrder = result;
//       app.appController.updateOrder(result);
//       print("✅ Order ${orderStatus ? 'Accepted' : 'Declined'}: ID ${updatedOrder.id}");
//
//     } else {
//       print("❌ Failed to update order status.");
//       // Optional: showSnackbar("Error", "Failed to update order status");
//     }
//   } catch (e) {
//     print("❌ Exception in getOrders: $e");
//     // Optional: showSnackbar("Api Error", "An error occurred: $e");
//   }
// }
//
// // Future<void> getOrders(String bearerKey, bool orderStatus, Order updatedOrder) async {
// //   Map<String, dynamic> jsonData = {
// //     "order_status": orderStatus ? 2 : 1,
// //     "approval_status": orderStatus ? 2 : 3,
// //   };
// //
// //   try {
// //     final result = await ApiRepo().orderAcceptDecline(bearerKey, jsonData, updatedOrder.id ?? 0);
// //
// //     if (result != null) {
// //       updatedOrder = result;
// //       app.appController.updateOrder(result);
// //
// //       // ✅ Handle Manual Accept + Auto Print
// //       SharedPreferences prefs = await SharedPreferences.getInstance();
// //       bool _autoOrderPrint = prefs.getBool('auto_order_print') ?? false;
// //
// //       if (_autoOrderPrint) {
// //         // Only print if order is ACCEPTED
// //         if (result.orderStatus == 2) { // 2 = Accepted
// //
// //           // Fetch updated order with invoice
// //           final refreshedOrder = await ApiRepo().getNewOrderData(bearerKey, updatedOrder.id!);
// //
// //           // Safe check for invoice
// //           if (refreshedOrder.invoice != null &&
// //               (refreshedOrder.invoice?.invoiceNumber ?? '').isNotEmpty) {
// //
// //             PrinterHelperEnglish.printTestFromSavedIp(
// //                 context: Get.context!, // Use Get.context or pass context properly
// //                 order: refreshedOrder,
// //                 store: storeName,
// //                 auto: true);
// //           } else {
// //             print("❌ Invoice missing after accept. Skipping print.");
// //           }
// //
// //         } else {
// //           print("ℹ️ Order not accepted yet. No auto print.");
// //         }
// //       }
// //
// //     } else {
// //       // Optional: showSnackbar("Error", "Failed to update order status");
// //     }
// //   } catch (e) {
// //     // Optional: showSnackbar("Api Error", "An error occurred: $e");
// //   }
// // }
import 'package:flutter/material.dart';
import 'package:food_app/api/repository/api_repository.dart';
import 'package:food_app/constants/constant.dart';
import 'package:food_app/models/Store.dart';
import 'package:food_app/models/order_model.dart';
import 'package:food_app/utils/log_util.dart';
import 'package:food_app/utils/my_application.dart';
import 'package:food_app/utils/printer_helper_english.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// BACKGROUND ORDERS REFRESH
Future<void> getOrdersInBackground() async {
  try {
    print("🔄 Global API called from background");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? bearerKey = prefs.getString(valueShared_BEARER_KEY);
    String? storeID = prefs.getString(valueShared_STORE_KEY);

    if (bearerKey == null) {
      print("❌ Bearer key not found in SharedPreferences");
      return;
    }

    DateTime formatted = DateTime.now();
    String date = DateFormat('yyyy-MM-dd').format(formatted);

    final Map<String, dynamic> data = {
      "store_id": storeID,
      "target_date": date,
      "limit": 0,
      "offset": 0,
    };

    final result = await ApiRepo().orderGetApiFilter(bearerKey, data);

    if (result.isNotEmpty && result.first.code == null) {
      print("✅ Background order fetch success: ${result.length} orders");

      // Safe update for background
      try {
        Future.delayed(Duration(milliseconds: 500), () {
          if (app.appController.searchResultOrder.isNotEmpty) {
            app.appController.setOrders(result);
            print("🔄 Orders updated in controller");
          }
        });
      } catch (e) {
        print("⚠️ Controller update failed (app not in foreground): $e");
      }
    } else {
      String errorMessage = result.isNotEmpty
          ? result.first.mess ?? "Unknown error"
          : "No data returned";
      print("⚠️ Background fetch error: $errorMessage");
    }
  } catch (e) {
    print("❌ Exception in background order fetch: $e");
  }
}

// FOREGROUND ORDER PROCESSING (ENHANCED)
Future<void> getOrdersInForegrund(BuildContext context, int orderID) async {
  try {
    print("📱 Foreground order processing started for: $orderID");

    bool _autoOrderAccept = false;
    bool _autoOrderPrint = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? bearerKey = prefs.getString(valueShared_BEARER_KEY);

    if (bearerKey == null) {
      print("❌ Bearer key not found in SharedPreferences");
      return;
    }

    final result = await ApiRepo().getNewOrderData(bearerKey, orderID);

    if (result != null) {
      app.appController.addNewOrder(result);
      print("📦 New order added to controller: ${result.id}");

      _autoOrderAccept = prefs.getBool('auto_order_accept') ?? false;
      _autoOrderPrint = prefs.getBool('auto_order_print') ?? false;

      print("⚙️ Auto settings - Accept: $_autoOrderAccept, Print: $_autoOrderPrint");

      if (_autoOrderAccept) {
        print("🤖 Auto accepting order in foreground");

        // Step 1: Accept the order first
        await getOrders(bearerKey, true, result);

        // Step 2: Wait for backend to process
        await Future.delayed(Duration(seconds: 2));

        // Step 3: Auto print if enabled
        if (_autoOrderPrint) {
          print("🖨️ Auto printing after accept");

          // Get updated order with invoice
          final updatedOrder = await ApiRepo().getNewOrderData(bearerKey, orderID);

          if (updatedOrder?.invoice != null &&
              (updatedOrder?.invoice?.invoiceNumber ?? '').isNotEmpty) {

            // Print the order
            PrinterHelperEnglish.printTestFromSavedIp(
                context: context,
                order: updatedOrder!,
                store: '',
                auto: true
            );
            print("✅ Foreground auto print completed");

          } else {
            print("❌ Invoice not ready after accept. Skipping print.");
          }
        }
      } else if (_autoOrderPrint && !_autoOrderAccept) {
        // Auto print only (without auto accept) - for manually accepted orders
        print("🖨️ Auto print only (no auto accept)");

        if (result.orderStatus == 2) { // Already accepted
          PrinterHelperEnglish.printTestFromSavedIp(
              context: context,
              order: result,
              store: '',
              auto: true
          );
        }
      }
    } else {
      String errorMessage = "Failed to get order data";
      showSnackbar("Error", errorMessage);
      print("❌ $errorMessage for order: $orderID");
    }
  } catch (e) {
    showSnackbar("Api Error", "An error occurred: $e");
    print("❌ Foreground order processing error: $e");
  }
}

// ORDER ACCEPT/DECLINE (ENHANCED)
Future<void> getOrders(String bearerKey, bool orderStatus, Order updatedOrder) async {
  Map<String, dynamic> jsonData = {
    "order_status": orderStatus ? 2 : 1,
    "approval_status": orderStatus ? 2 : 3,
  };

  try {
    print("📤 ${orderStatus ? 'Accepting' : 'Declining'} order: ${updatedOrder.id}");

    final result = await ApiRepo().orderAcceptDecline(bearerKey, jsonData, updatedOrder.id ?? 0);

    if (result != null) {
      updatedOrder = result;

      // Safe controller update
      try {
        app.appController.updateOrder(result);
        print("✅ Order ${orderStatus ? 'Accepted' : 'Declined'}: ID ${updatedOrder.id}");
      } catch (e) {
        print("⚠️ Controller update failed: $e");
      }

    } else {
      print("❌ Failed to update order status for: ${updatedOrder.id}");
    }
  } catch (e) {
    print("❌ Exception in getOrders: $e");
  }
}

// BACKGROUND-SAFE ORDER PROCESSING
Future<void> processOrderInBackground(int orderID) async {
  try {
    print("🌙 Background order processing: $orderID");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? bearerKey = prefs.getString(valueShared_BEARER_KEY);
    bool autoAccept = prefs.getBool('auto_order_accept') ?? false;
    bool autoPrint = prefs.getBool('auto_order_print') ?? false;

    if (bearerKey == null) return;

    // Get order data
    final orderData = await ApiRepo().getNewOrderData(bearerKey, orderID);
    if (orderData == null) return;

    // Auto accept
    if (autoAccept) {
      await getOrders(bearerKey, true, orderData);
      await Future.delayed(Duration(seconds: 2));

      // Auto print after accept
      if (autoPrint) {
        final updatedOrder = await ApiRepo().getNewOrderData(bearerKey, orderID);
        if (updatedOrder?.invoice != null) {
          // Background print logic here
          print("🖨️ Background printing order: $orderID");
        }
      }
    }

    // Refresh orders
    await getOrdersInBackground();

  } catch (e) {
    print("❌ Background processing error: $e");
  }
}