import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:food_app/api/repository/api_repository.dart';
import 'package:food_app/constants/constant.dart';
import 'package:food_app/models/OrderItem.dart';
import 'package:food_app/models/Store.dart';
import 'package:food_app/models/order_model.dart';
import 'package:food_app/utils/log_util.dart';
import 'package:food_app/utils/my_application.dart';
import 'package:food_app/utils/printer_helper_english.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/print_order_without_ip.dart';

class OrderDetailEnglish extends StatefulWidget {
  final Order order;

  OrderDetailEnglish(this.order);

  @override
  _OrderDetailState createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetailEnglish> {
  late SharedPreferences sharedPreferences;
  String? bearerKey;
  late Order updatedOrder;
  int? orderType = 0;
  String? storeName;
  String? storeid;
  bool isPrint = false;
  bool isAutoAccept = false;
  bool isLoading = false;
  Timer? _orderTimer;
  @override
  void initState() {
    super.initState();
    initVar();
  }
  @override
  void dispose() {
    _orderTimer?.cancel();
    super.dispose();
  }
  Future<void> initVar() async {
    updatedOrder = widget.order;
    sharedPreferences = await SharedPreferences.getInstance();
    bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);

    if (bearerKey != null) {
      // ✅ CRITICAL: Wait for store name to be loaded before proceeding
      await getStoredta(bearerKey!);
      print("✅ Store name loaded in initVar: $storeName");
    }
  }

// Replace the getOrders() method:
  Future<void> getOrders(String bearerKey, bool isAccept) async {
    Map<String, dynamic> jsonData = {
      "order_status": 2,
      "approval_status": isAccept ? 2 : 3,
    };

    try {
      Get.dialog(
        Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            )),
        barrierDismissible: false,
      );
      _orderTimer = Timer(Duration(seconds: 7), () {
        if (Get.isDialogOpen ?? false) {
          Get.back();
          showSnackbar("order Timeout", "get Details request timed out. Please try again.");
        }
      });

      final prefs = await SharedPreferences.getInstance();
      bool _autoOrderPrint = prefs.getBool('auto_order_print') ?? false;
      bool _isAutoAccept = prefs.getBool('is_auto_accept') ?? false;

      // ✅ NEW: Add timeout wrapper around API call
      final result = await Future.any([
        ApiRepo().orderAcceptDecline(bearerKey, jsonData, updatedOrder.id ?? 0),

    Future.delayed(Duration(seconds: 10)).then((_) => null)
      ]);
      _orderTimer?.cancel();
      Get.back();

      // ✅ NEW: Check if result is null due to timeout
      if (result == null) {
        Get.snackbar(
          'Timeout',
          'Request timed out. Please try again.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
        return; // Exit early on timeout
      }

      if (result != null) {
        setState(() {
          isPrint = true;
          updatedOrder = result;
          app.appController.updateOrder(result);
          orderType = isAccept ? 1 : 2;
        });

        if (isAccept && _autoOrderPrint && !_isAutoAccept) {
          final refreshedOrder = await ApiRepo().getNewOrderData(bearerKey, updatedOrder.id!);

          if (refreshedOrder.invoice != null &&
              (refreshedOrder.invoice?.invoiceNumber ?? '').isNotEmpty) {

            // ✅ Try multiple approaches to get store name
            String? finalStoreName = storeName;

            if (finalStoreName == null || finalStoreName.isEmpty) {
              print("⚠️ Store name is null, trying to fetch...");
              finalStoreName = await getStoredta(bearerKey);
            }

            if (finalStoreName == null || finalStoreName.isEmpty) {
              print("⚠️ Still null, trying fallback...");
              finalStoreName = await getStoreNameFallback();
            }

            print("🖨️ Final store name for printing: '$finalStoreName'");

            PrinterHelperEnglish.printTestFromSavedIp(
                context: Get.context!,
                order: refreshedOrder,
                store: finalStoreName ?? "Restaurant",
                auto: true);
          }
        }
      }

    } catch (e) {
      _orderTimer?.cancel();
      Get.back();

      // ✅ NEW: Different error message for timeout vs other errors
      String errorMessage = e.toString().contains('timeout')
          ? 'Request timed out. Please check your connection and try again.'
          : 'Order Accept API Exception: $e';

      if (e.toString().contains('timeout')) {
        Get.snackbar(
          'Timeout Error',
          errorMessage,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: Duration(seconds: 3),
        );
      }

      Log.loga(title, errorMessage);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String?> getStoredta(String bearerKey) async {
    try {
      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
      print("🔍 DEBUG - bearerKey: ${bearerKey.substring(0, 10)}...");
      print("🔍 DEBUG - storeID: $storeID");

      if (storeID == null) {
        print("❌ DEBUG - Store ID is null, cannot fetch store data");
        return null;
      }

      print("🌐 DEBUG - Calling ApiRepo().getStoreData...");
      final result = await ApiRepo().getStoreData(bearerKey, storeID);
      print("🔍 DEBUG - API result: ${result != null ? 'Success' : 'Null'}");

      if (result != null) {
        Store store = result;
        print("🔍 DEBUG - Store object: ${store.toString()}");
        print("🔍 DEBUG - Store name from API: ${store.name}");

        String fetchedStoreName = store.name?.toString() ?? "Unknown Store";
        String fetchedStoreid = store.code?.toString() ?? "Unknown id";

        setState(() {
          storeName = fetchedStoreName;
          storeID = fetchedStoreid;
        });

        print("✅ DEBUG - Final storeName set to: '$storeName'");
        return storeName;
      } else {
        print("❌ DEBUG - API returned null result");
        showSnackbar("Error", "Failed to get store data");
        return null;
      }
    } catch (e) {
      print("❌ DEBUG - Exception in getStoredta: $e");
      print("❌ DEBUG - Exception type: ${e.runtimeType}");
      Log.loga(title, "getStoredta Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
      return null;
    }
  }

  Future<String?> getStoreNameFallback() async {
    try {
      // Try to get from previous session
      String? cachedName = sharedPreferences.getString('last_store_name');
      if (cachedName != null && cachedName.isNotEmpty) {
        print("✅ Using cached store name: $cachedName");
        return cachedName;
      }

      // Try to get from user preferences or default
      return "Default Restaurant"; // Replace with your app's default name
    } catch (e) {
      print("❌ Fallback failed: $e");
      return "Restaurant";
    }
  }

  String formatAmount(double? amount) {
    if (amount == null) return "0";

    final locale = Get.locale?.languageCode ?? 'en';
    String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
    return NumberFormat('#,##0.00#', localeToUse).format(amount);
  }

  String formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return '';
    }

    try {
      DateTime dateTime = DateTime.parse(dateTimeString);
      String date = DateFormat('dd-MM-yyyy').format(dateTime);
      String time = DateFormat('HH:mm').format(dateTime);
      return '$date  $time';
    } catch (e) {
      return dateTimeString;
    }
  }
  @override
  Widget build(BuildContext context) {
    if (updatedOrder == null) {
      return Center(child: CircularProgressIndicator());
    }

    //var amount = (updatedOrder.payment?.amount ?? 0.0).toStringAsFixed(1);
    var amount = (updatedOrder.invoice?.totalAmount ?? 0.0).toStringAsFixed(1);
    var discount = (updatedOrder.invoice?.discount_amount ?? 0.0).toStringAsFixed(1);
    var delFee = (updatedOrder.invoice?.delivery_fee ?? 0.0).toStringAsFixed(1);
    // Calculate subtotal from all items
    final subtotal = updatedOrder.items?.fold<double>(0, (sum, item) {
      if (item == null) return sum;

      // Toppings total for this item
      final toppingsTotal = item.toppings?.fold<double>(
        0,
            (tSum, topping) => tSum + ((topping.price ?? 0) * (topping.quantity ?? 0)),
      ) ?? 0;

      // Item total (unit price + toppings) * quantity
      final itemTotal = ((item.unitPrice ?? 0) + toppingsTotal) * (item.quantity ?? 0);

      return sum + itemTotal;
    }) ?? 0;
    final discountData = updatedOrder.invoice?.discount_amount ?? 0.0;
    final deliveryFee = updatedOrder.invoice?.delivery_fee ?? 0.0;
    final grandTotal = subtotal - discountData + deliveryFee;
    var Note=updatedOrder.note.toString();
    String guestAddress=updatedOrder.guestShippingJson?.line1?.toString()??'';
    String guestName=updatedOrder.guestShippingJson?.customerName?.toString()??'';
    String guestPhone=updatedOrder.guestShippingJson?.phone?.toString()??'';
    print('guest name is $guestName');
    print('guest name is $guestAddress');
    print('guest name is $guestPhone');
    print('Note IS $Note');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'order_details'.tr,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 30,
              width: 30,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SizedBox(
              height: 30,
              width: 25,
              child: IconButton(
                icon: Icon(
                    updatedOrder.orderType == 1
                        ? Icons.car_crash_outlined
                        : Icons.receipt,
                    color: Colors.blue),
                onPressed: () {
                  Navigator.pop(context);
                  // Add your icon's functionality here
                },
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.print,
              color: (updatedOrder.approvalStatus == 2) ? Colors.blue : Colors.grey,
            ),
            onPressed: (updatedOrder.approvalStatus == 2)
                ? () {

              printData(updatedOrder);
            }
                : null,
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.fromLTRB(10, 0, 10, 5),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 1,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 5),
                    Center(
                      child: Text(
                        '${'order_id'.tr} # ${updatedOrder.id ?? ''}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    SizedBox(height: 2),
                    Center(
                      child: Text(
                        '${'invoice_number'.tr}: ${updatedOrder.invoice?.invoiceNumber ?? ''}',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                    SizedBox(height: 2),
                    Center(
                      child: Text(
                        '${'date'.tr}: ${formatDateTime(updatedOrder.createdAt)}',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                    SizedBox(height: 2),
                    if (updatedOrder.deliveryTime != null && updatedOrder.deliveryTime!.isNotEmpty)
                      Center(
                        child: Text(
                          '${'delivery_time'.tr}: ${formatDateTime(updatedOrder.deliveryTime)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                      ),
                    SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    SizedBox(height: 2),
                    Text(
                      '${'customer'.tr}: '
                          '${(updatedOrder.shipping_address?.customer_name != null && updatedOrder.shipping_address!.customer_name!.isNotEmpty)
                          ? updatedOrder.shipping_address!.customer_name!
                          : guestName}',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    if (updatedOrder.orderType == 1)
                      Text(
                        '${'address'.tr}: ${(updatedOrder.shipping_address?.line1 != null && updatedOrder.shipping_address!.line1!.isNotEmpty)
                            ? "${updatedOrder.shipping_address!.line1!}, ${updatedOrder.shipping_address?.city ?? ""}"
                            : guestAddress}',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    SizedBox(height: 2),
                    Text(
                      '${'phone'.tr}: ${(updatedOrder.shipping_address?.phone != null && updatedOrder.shipping_address!.phone!.isNotEmpty)
                          ? updatedOrder.shipping_address!.phone!
                          : guestPhone}',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    SizedBox(height: 2),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.all(1),
                      itemCount: updatedOrder.items?.length ?? 0,
                      itemBuilder: (context, index) {
                        final item = updatedOrder.items?[index];
                        if (item == null) return SizedBox.shrink();

                        final toppingsTotal = item.toppings?.fold<double>(
                          0,
                              (sum, topping) => sum + ((topping.price ?? 0) * (topping.quantity ?? 0)),
                        ) ?? 0;
                        final itemTotal = ((item.unitPrice ?? 0) + toppingsTotal) * (item.quantity ?? 0);

                        return _orderItem(
                          item.productName ?? "Unknown",
                          itemTotal.toString(),
                          item,
                          note: item.note ?? "",
                        );
                      },
                    ),
                    SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    Note != null && Note.trim().isNotEmpty
                        ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Note:  ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.green,
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          child: Text(
                            Note,
                            style: TextStyle(
                              fontWeight: FontWeight.w300,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    )
                        : SizedBox.shrink(),

                    SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    Visibility(
                      visible: isPrint,
                      child: Column(
                        children: [
                          SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'subtotal'.tr,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                formatAmount(subtotal),
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),]
                          ),
                    SizedBox(height: 2),
                          Visibility(
                            visible: discountData == 0.0 ? false : true,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'discount'.tr,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                ),
                                Text(formatAmount(discountData),
                                 // discountData.toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 2),
                          Visibility(
                            visible: delFee == "0.0" ? false : true,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'delivery_fee'.tr,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                ),
                                Text(formatAmount(deliveryFee),
                                  //delFee.toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 2),
                          Container(height: 0.5, color: Colors.grey),
                          SizedBox(height: 2),
                          // Row(
                          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //   children: [
                          //     Text(
                          //       'grand_total'.tr,
                          //       style: TextStyle(
                          //           fontWeight: FontWeight.w500, fontSize: 13),
                          //     ),
                          //     Text(
                          //       "${'currency'.tr} ${updatedOrder.invoice!.totalAmount} ",
                          //      // "${'currency'.tr} ${updatedOrder.payment?.amount?.toStringAsFixed(1) ?? "0"} ",
                          //       style: TextStyle(
                          //           fontWeight: FontWeight.w500, fontSize: 13),
                          //     ),
                          //   ],
                          // ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'grand_total'.tr,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 13),
                              ),

                              Text(
                                "${'currency'.tr} ${formatAmount((grandTotal))}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                              // Text("${'currency'.tr} ${formatAmount(updatedOrder.invoice?.totalAmount ?? 0.0)}",
                              //   //"${'currency'.tr} ${updatedOrder.invoice?.totalAmount?.toStringAsFixed(1) ?? "0"} ",
                              //   style: TextStyle(
                              //       fontWeight: FontWeight.w500, fontSize: 13),
                              // ),
                            ],
                          ),

                          SizedBox(height: 2),
                          Container(height: 0.5, color: Colors.grey),
                        ],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "${'invoice_number'.tr}: ${updatedOrder.invoice?.invoiceNumber ?? ''}",
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    Text(
                      "${'payment_method'.tr}: ${updatedOrder.payment?.paymentMethod ?? ''}",
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "${'paid'.tr}: ${formatDateTime(updatedOrder.createdAt ?? '')}",
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    SizedBox(height: 2),
                    if (updatedOrder.brutto_netto_summary?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'vat_rate'.tr,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Text(
                                      'gross'.tr,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Center(
                                    child: Text(
                                      'net'.tr,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'vat'.tr,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 2),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.all(12),
                              itemCount: updatedOrder.brutto_netto_summary?.length ?? 0,
                              itemBuilder: (context, index) {
                                final tax = updatedOrder.brutto_netto_summary?[index];
                                if (tax == null) return SizedBox.shrink();
                                return brutoItems(
                                  '${tax.taxRate?.toStringAsFixed(0) ?? "0"} %',
                                  tax.brutto?.toString() ?? "0",
                                  tax.netto?.toString() ?? "0",
                                  tax.tax_amount?.toString() ?? "0",
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              child: _buildActionButtons(
                  context, updatedOrder.approvalStatus ?? 0),
            ),
            SizedBox(height: 30,)
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, int approvalStatus) {
    if (orderType == 0) {
      if (approvalStatus == 1) {
        setState(() {
          isPrint = false;
        });
        return Column(
          children: [
            Center(
              child: Text("status_pending".tr,
                  style: TextStyle(
                      fontWeight: FontWeight.w400, color: Colors.orangeAccent)),
            ),
            SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(context, Icons.close, "decline".tr, Colors.red),
                _actionButton(context, Icons.check, "accept".tr, Colors.green),
              ],
            )
          ],
        );
      } else if (approvalStatus == 2) {
        setState(() {
          isPrint = true;
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text("status_accepted".tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green[400])),
            ),
            SizedBox(height: 10),
          ],
        );
      } else if (approvalStatus == 3) {
        setState(() {
          isPrint = true;
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text("status_decline".tr,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red[400]!)),
            ),
            SizedBox(height: 3),
          ],
        );
      }
    } else {
      if (orderType == 1) {
        setState(() {
          isPrint = true;
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text("status_accepted".tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 3),
          ],
        );
      } else if (orderType == 2) {
        setState(() {
          isPrint = true;
        });
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Text("status_decline".tr,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 3),
          ],
        );
      }
    }
    return SizedBox.shrink();
  }

  Widget _orderItem(String title, String price, OrderItem item, {String? note}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product title and price row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${item.quantity ?? 0}X $title'
                      '${((item.toppings?.isNotEmpty ?? false) && item.variant == null) ? ' [${formatAmount(item.unitPrice)}]' : ''}',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
              Text(
                '${'currency'.tr} ${formatAmount(double.parse(price))}',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ],
          ),

          // Variant info
          if (item.variant != null)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 2),
              child: Text("${item.quantity} × ${item.variant!.name ?? ''} [${formatAmount(item.variant!.price ?? 0)} ${'currency'.tr}]",
                  style: TextStyle(fontWeight: FontWeight.w400, fontSize: 13)
              ),
            ),

          // Toppings info
          if ((item.toppings?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: item.toppings!.map((topping) {
                  final totalPrice = (topping.price ?? 0) * (topping.quantity ?? 0);
                  return Text("${topping.quantity} × ${topping.name} [${formatAmount(totalPrice)}]",
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget brutoItems(String percentage, String brutto, String netto, String? taxAmount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                percentage,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(formatAmount(double.tryParse(brutto) ?? 0),
                //netto,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text( formatAmount(double.tryParse(netto) ?? 0),
               // brutto,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(formatAmount(double.tryParse(taxAmount ?? "0") ?? 0),
               // taxAmount ?? "0",
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(BuildContext context, IconData icon, String label, Color color) {
    return GestureDetector(
        onTap: () async {
          if (bearerKey == null) return;

          if (label == 'accept'.tr) {
            setState(() {
              isAutoAccept = false;
              isLoading = true; // Show loader
            });

            sharedPreferences.setBool('is_auto_accept', false);

            // Give UI a chance to rebuild
            await Future.delayed(Duration(milliseconds: 200));

            getOrders(bearerKey!, true);

          } else if (label == 'decline'.tr) {
            setState(() {
              isLoading = true; // Show loader
            });

            await Future.delayed(Duration(milliseconds: 200));

            getOrders(bearerKey!, false);
            setState(() {
            isLoading = false;
          });
          // API ke complete hone par isLoading = false karo
          }
        },
        child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            height: 40,
            width: 120,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              textAlign: TextAlign.center,
              label,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
            ),
          )
        ],
      ),
    );
  }

  void printData(Order order) async {
    print("🖨️ DEBUG - printData called");

    if (order.approvalStatus != 2) {
      print("❌ DEBUG - Order not accepted, approval status: ${order.approvalStatus}");
      showSnackbar("Error", "Cannot print pending order. Please accept the order first.");
      return;
    }

    if (storeName == null) {
      print("❌ DEBUG - Store name is null");
      showSnackbar("Error", "Store name not available");
      return;
    }

    String? localIP = sharedPreferences.getString('printer_ip_0');
    print("🔍 DEBUG - Local IP from SharedPreferences: $localIP");

    if (localIP == null || localIP.isEmpty) {
      print("📡 DEBUG - Local IP is null/empty, calling printWithoutLocalIp()");
      await printWithoutLocalIp();
    } else {
      print("🖨️ DEBUG - Local IP available, calling PrinterHelperEnglish.printTestFromSavedIp()");
      PrinterHelperEnglish.printTestFromSavedIp(
          context: context,
          order: order,
          store: storeName!,
          auto: false);
    }
  }
  void showSnackbar(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
      ),
    );
  }


  Future<void> printWithoutLocalIp() async {
    print("📡 DEBUG - printWithoutLocalIp called");

    setState(() {
      isLoading = true;
    });

    String? dynamicStoreId = sharedPreferences.getString(valueShared_STORE_KEY);

    print("🔍 DEBUG - Store ID from SharedPreferences: $dynamicStoreId");
    print("🔍 DEBUG - Current storeid variable: $storeid");
    String finalStoreId = dynamicStoreId ?? storeid ?? '';

    print("✅ DEBUG - Final store ID being sent: $finalStoreId");

    var map = {
      "order_id": updatedOrder.id ?? '',
      "store_id": finalStoreId
    };

    print("📋 DEBUG - Print Without local Ip map: $map");

    try {
      Get.dialog(
        Center(
            child: Lottie.asset(
              'assets/animations/burger.json',
              width: 150,
              height: 150,
              repeat: true,
            )
        ),
        barrierDismissible: false,
      );

      printOrderWithoutIp model = await CallService().printWithoutIp(map);

      setState(() {
        isLoading = false;
      });
      Get.back();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Print Details Sent Successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      print("✅ DEBUG - Print without IP successful");

    } catch (e) {
      setState(() {
        isLoading = false;
      });

      Get.back();

      print('❌ DEBUG - Print without IP error: $e');

      // Handle error case
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred during Sending Details.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }



}
