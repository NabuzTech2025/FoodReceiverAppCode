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

  @override
  void initState() {
    super.initState();
    initVar();
  }

// Replace the initVar() method in OrderDetailEnglish.dart:
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

      final prefs = await SharedPreferences.getInstance();
      bool _autoOrderPrint = prefs.getBool('auto_order_print') ?? false;
      bool _isAutoAccept = prefs.getBool('is_auto_accept') ?? false;

      final result = await ApiRepo().orderAcceptDecline(bearerKey, jsonData, updatedOrder.id ?? 0);
      Get.back();

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
      Get.back();
      Log.loga(title, "Order Accept API Exception: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

// Update the getStoredta() method to be more reliable:
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

// Alternative approach - get store name from SharedPreferences if available:
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
          Visibility(
            visible: true /*isPrint*/,
            child: IconButton(
              icon: const Icon(Icons.print, color: Colors.blue),
              onPressed: () {
                printData(updatedOrder);
              },
            ),
          ),
        ],
      ),
      body:
      Container(
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
                        '${'date'.tr}: ${updatedOrder.createdAt ?? ''}',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                    SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    SizedBox(height: 2),
                    Text(
                      '${'customer'.tr}: ${updatedOrder.shipping_address?.customer_name ?? ""}',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    if (updatedOrder.orderType == 1)
                      Text(
                        '${'address'.tr}: ${updatedOrder.shipping_address?.line1 ?? ""}, ${updatedOrder.shipping_address?.city ?? ""}',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    SizedBox(height: 2),
                    Text(
                      '${'phone'.tr}: ${updatedOrder.shipping_address?.phone ?? ""}',
                      style:
                          TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
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
                                style: TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 13),
                              ),

                              Text(
                                "${'currency'.tr} ${formatAmount(double.parse(amount))}",
                                style: TextStyle(
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
                      "${'paid'.tr}: ${updatedOrder.createdAt ?? ''}",
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
      // onTap: () {
      //   if (bearerKey == null) return;
      //
      //   if (label == 'accept'.tr) {
      //     setState(() {
      //       isAutoAccept = false;
      //       isLoading=true;// Manual accept
      //     });
      //     sharedPreferences.setBool('is_auto_accept', false);
      //     getOrders(bearerKey!, true);
      //   } else if (label == 'decline'.tr) {
      //     getOrders(bearerKey!, false);
      //   }
      // },
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

            // Jab API complete ho jaye, tab isLoading ko false karo
            // Example:
            // setState(() {
            //   isLoading = false;
            // });
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

  void printData(Order order) {
    if (storeName == null) return;
    /* PrinterHelper.printTestFromSavedIp(
        context: context, order: order, store: storeName!); */
    PrinterHelperEnglish.printTestFromSavedIp(
        context: context,
        order: order,
        store: storeName!,
        auto: false);
  }

  void showSnackbar(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
      ),
    );
  }
}
