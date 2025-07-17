import 'package:flutter/material.dart';
import 'package:food_app/api/repository/api_repository.dart';
import 'package:food_app/constants/constant.dart';
import 'package:food_app/models/OrderItem.dart';
import 'package:food_app/models/Store.dart';
import 'package:food_app/models/order_model.dart';
import 'package:food_app/utils/log_util.dart';
import 'package:food_app/utils/my_application.dart';
import 'package:food_app/utils/printer_dummy.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderDetail extends StatefulWidget {
  final Order order;

  OrderDetail(this.order);

  @override
  _OrderDetailState createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  late SharedPreferences sharedPreferences;
  String? bearerKey;
  late Order updatedOrder;
  int? orderType = 0;
  String? storeName;
  bool isPrint = false;

  @override
  void initState() {
    super.initState();
    initVar();
  }

  Future<void> initVar() async {
    updatedOrder = widget.order;
    sharedPreferences = await SharedPreferences.getInstance();
    bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
    if (bearerKey != null) {
      getStoredta(
        bearerKey!,
      );
    }
  }

  Future<void> getStoredta(String bearerKey) async {
    try {
      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
      final result = await ApiRepo().getStoreData(bearerKey, storeID!);

      if (result != null) {
        Store store = result;
        setState(() {
          storeName = store.name.toString();
          print("StoreName2 " + storeName!);
        });
      } else {
        showSnackbar("Error", "Failed to get store data");
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }

  Future<void> getOrders(String bearerKey, bool orderStatus) async {
    Map<String, dynamic> jsonData = {
      "order_status": orderStatus ? 2 : 1,
      "approval_status": orderStatus ? 2 : 3,
    };

    try {
      final result = await ApiRepo()
          .orderAcceptDecline(bearerKey, jsonData, updatedOrder.id ?? 0);

      if (result != null) {
        setState(() {
          isPrint = true;
          updatedOrder = result;
          app.appController.updateOrder(result);
          orderType = orderStatus ? 1 : 2;
        });
      } else {
        showSnackbar("Error", "Failed to update order status");
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (updatedOrder == null) {
      return Center(child: CircularProgressIndicator());
    }

    var amount = (updatedOrder.payment?.amount ?? 0.0).toStringAsFixed(1);
    var discount =
    (updatedOrder.invoice?.discount_amount ?? 0.0).toStringAsFixed(1);
    var delFee = (updatedOrder.invoice?.delivery_fee ?? 0.0).toStringAsFixed(1);
    var preSubTotal =
    (double.parse(amount) + double.parse(discount) - double.parse(delFee))
        .toStringAsFixed(1);
    final subtotal = preSubTotal;

    final discountData = updatedOrder.invoice?.discount_amount ?? 0.0;
    final deliveryFee = updatedOrder.invoice?.delivery_fee ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Order Detail',
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
                        ? Icons.receipt
                        : Icons.car_crash_outlined,
                    color: Colors.blue),
                onPressed: () {
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
                        "Order # ${updatedOrder.id ?? ''}",
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    SizedBox(height: 2),
                    Center(
                      child: Text(
                        "Rcchnungsnr: ${updatedOrder.invoice?.invoiceNumber ?? ''}",
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                    SizedBox(height: 2),
                    Center(
                      child: Text(
                        "Datum: ${updatedOrder.createdAt ?? ''}",
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    ),
                    SizedBox(height: 2),
                    Container(height: 0.5, color: Colors.grey),
                    SizedBox(height: 2),
                    Text(
                      "Kunde: ${updatedOrder.shipping_address?.customer_name ?? ""}",
                      style:
                      TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    if (updatedOrder.orderType == 1)
                      Text(
                        "Address: ${updatedOrder.shipping_address?.line1 ?? ""}, ${updatedOrder.shipping_address?.city ?? ""}",
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 13),
                      ),
                    SizedBox(height: 2),
                    Text(
                      "Telefon: ${updatedOrder.shipping_address?.phone ?? ""}",
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
                        final order = updatedOrder.items?[index];
                        if (order == null) return SizedBox.shrink();
                        return _orderItem(
                          order.productName ?? "Unknown",
                          order.unitPrice?.toString() ?? "0",
                          order,
                          note: order.note ?? "",
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
                                "Zwischenesumme:",
                                style: TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                              Text(
                                subtotal,
                                style: TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Visibility(
                            visible: discountData == 0.0 ? false : true,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Rabbat:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                ),
                                Text(
                                  discountData.toString(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 2),
                          Visibility(
                            visible: delFee == "0.0"? false : true,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Liefergebuhr:",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13),
                                ),
                                Text(
                                  delFee.toString(),
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
                                "Gesamt:",
                                style: TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                              Text(
                                "${updatedOrder.payment?.amount?.toStringAsFixed(1) ?? "0"} €",
                                style: TextStyle(
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
                      "Rcchnungsnr: ${updatedOrder.invoice?.invoiceNumber ?? ''}",
                      style:
                      TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    Text(
                      "Zahlungsart: ${updatedOrder.payment?.paymentMethod ?? ''}",
                      style:
                      TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Bezahlt: ${updatedOrder.createdAt ?? ''}",
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
                                      "MWSt-Satz",
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
                                      "Brutto",
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
                                      "Netto",
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
                                      "MWSt",
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
                              itemCount:
                              updatedOrder.brutto_netto_summary?.length ??
                                  0,
                              itemBuilder: (context, index) {
                                final tax =
                                updatedOrder.brutto_netto_summary?[index];
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
            // This will stick to the bottom
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: _buildActionButtons(
                  context, updatedOrder.approvalStatus ?? 0),
            ),
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
              child: Text("Status: Pending",
                  style: TextStyle(
                      fontWeight: FontWeight.w400, color: Colors.orangeAccent)),
            ),
            SizedBox(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(context, Icons.close, "Decline", Colors.red),
                _actionButton(context, Icons.check, "Accept", Colors.green),
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
              child: Text("Status: Accepted",
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
              child: Text("Status: Decline",
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
              child: Text("Status: Accepted",
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
              child: Text("Status: Decline",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 3),
          ],
        );
      }
    }
    return SizedBox.shrink();
  }

  Widget _orderItem(String title, String price, OrderItem item,
      {String? note}) {
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
                  '${item.quantity ?? 0}X $title',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3,
                ),
              ),
              Text(
                '€ ${((item.unitPrice ?? 0) * (item.quantity ?? 0)).toStringAsFixed(1)}',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ],
          ),
          if (item.variant != null)
            Row(
              children: [
                Text(
                  "${item.quantity}" + " x ",
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  "${item.variant!.name ?? ""}",
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  " [${item.variant!.price ?? 0} €]",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          if (note?.isNotEmpty ?? false)
            Text(
              "+ $note",
              style: const TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget brutoItems(
      String percentage, String brutto, String netto, String? taxAmount) {
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
              child: Text(
                netto,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                brutto,
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                taxAmount ?? "0",
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
      BuildContext context, IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        if (bearerKey == null) return;

        if (label == "Accept") {
          getOrders(bearerKey!, true);
        } else if (label == "Decline") {
          getOrders(bearerKey!, false);
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
    PrinterHelper.printTestFromSavedIp(
        context: context, order: order, store: storeName!);
  }

  void showSnackbar(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
      ),
    );
  }
}
