import 'package:flutter/material.dart';
import 'package:food_app/models/order_history_response_model.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/repository/api_repository.dart';
import '../utils/printer_helper_english.dart';

class OrderHistoryDetails extends StatefulWidget {
  final orderHistoryResponseModel historyOrder; // Add this parameter

  const OrderHistoryDetails({super.key, required this.historyOrder}); // Make it required

  @override
  State<OrderHistoryDetails> createState() => _OrderHistoryDetailsState();
}

class _OrderHistoryDetailsState extends State<OrderHistoryDetails> {
  // Remove the late declaration and use widget.historyOrder instead
  // late orderHistoryResponseModel historyOrder;

  int? orderType = 0;
  bool isPrint = false;
  bool isAutoAccept = false;
  bool isLoading = false;
  late SharedPreferences sharedPreferences;
  String? bearerKey;
  String? storeName;

  @override
  void initState() {
    super.initState();
    // Initialize any required data here
    _initializeData();
  }

  void _initializeData() async {
    // Initialize shared preferences and other data
    sharedPreferences = await SharedPreferences.getInstance();
    storeName = sharedPreferences.getString('store_name');
    bearerKey = sharedPreferences.getString('bearer_key');
    setState(() {});
  }

  void printData(orderHistoryResponseModel history) {
    // ✅ Check if order is accepted before printing
    if (history.approvalStatus != 2) {
      showSnackbar("Error", "Cannot print pending order. Please accept the order first.");
      return;
    }

    if (storeName == null) {
      showSnackbar("Error", "Store name not available");
      return;
    }

    PrinterHelperEnglish.printHistoryFromSavedIp(
        context: context,
        order: history,
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

  @override
  Widget build(BuildContext context) {
    // Use widget.historyOrder instead of historyOrder
    final historyOrder = widget.historyOrder;

    final subtotal = historyOrder.items?.fold<double>(0, (sum, item) {
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

    final discountData = historyOrder.invoice?.discountAmount ?? 0.0;
    final deliveryFee = historyOrder.invoice?.deliveryFee ?? 0.0;
    final grandTotal = subtotal - discountData + deliveryFee;
    var delFee = (historyOrder.invoice?.deliveryFee ?? 0.0).toStringAsFixed(1);
    var Note = historyOrder.note.toString();

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
                    historyOrder.orderType == 1
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
              color: (historyOrder.approvalStatus == 2) ? Colors.blue : Colors.grey,
            ),
            onPressed: (historyOrder.approvalStatus == 2)
                ? () {
              printData(historyOrder);
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
                        '${'order_id'.tr} # ${historyOrder.id ?? ''}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    SizedBox(height: 2),
                    Center(
                      child: Text(
                        '${'invoice_number'.tr}: ${historyOrder.invoice?.invoiceNumber ?? ''}',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                    SizedBox(height: 2),
                    Center(
                      child: Text(
                        '${'date'.tr}: ${historyOrder.createdAt ?? ''}',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                    SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    SizedBox(height: 2),
                    Text(
                      '${'customer'.tr}: ${historyOrder.shippingAddress?.customerName ?? ""}',
                      style:
                      TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    if (historyOrder.orderType == 1)
                      Text(
                        '${'address'.tr}: ${historyOrder.shippingAddress?.line1 ?? ""}, ${historyOrder.shippingAddress?.city ?? ""}',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    SizedBox(height: 2),
                    Text(
                      '${'phone'.tr}: ${historyOrder.shippingAddress?.phone ?? ""}',
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
                      itemCount: historyOrder.items?.length ?? 0,
                      itemBuilder: (context, index) {
                        final item = historyOrder.items?[index];
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
                            ],
                          ),

                          SizedBox(height: 2),
                          Container(height: 0.5, color: Colors.grey),
                        ],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "${'invoice_number'.tr}: ${historyOrder.invoice?.invoiceNumber ?? ''}",
                      style:
                      TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    Text(
                      "${'payment_method'.tr}: ${historyOrder.payment?.paymentMethod ?? ''}",
                      style:
                      TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "${'paid'.tr}: ${historyOrder.createdAt ?? ''}",
                      style:
                      TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    SizedBox(height: 2),
                    if (historyOrder.bruttoNettoSummary?.isNotEmpty ?? false)
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
                              itemCount: historyOrder.bruttoNettoSummary?.length ?? 0,
                              itemBuilder: (context, index) {
                                final tax = historyOrder.bruttoNettoSummary?[index];
                                if (tax == null) return SizedBox.shrink();
                                return brutoItems(
                                  '${tax.taxRate?.toStringAsFixed(0) ?? "0"} %',
                                  tax.brutto?.toString() ?? "0",
                                  tax.netto?.toString() ?? "0",
                                  tax.taxAmount?.toString() ?? "0",
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
                  context, historyOrder.approvalStatus ?? 0),
            ),
            SizedBox(height: 30,)
          ],
        ),
      ),
    );
  }

  String formatAmount(double? amount) {
    if (amount == null) return "0";

    final locale = Get.locale?.languageCode ?? 'en';
    String localeToUse = locale == 'de' ? 'de_DE' : 'en_US';
    return NumberFormat('#,##0.00#', localeToUse).format(amount);
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

  Widget _orderItem(String title, String price, Items item, {String? note}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(formatAmount(double.tryParse(netto) ?? 0),
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(formatAmount(double.tryParse(taxAmount ?? "0") ?? 0),
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}