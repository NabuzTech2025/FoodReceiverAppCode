import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:food_app/api/repository/api_repository.dart';
import 'package:food_app/constants/constant.dart';
import 'package:food_app/customView/custom_button.dart';
import 'package:food_app/models/OrderItem.dart';
import 'package:food_app/models/Store.dart';
import 'package:food_app/models/order_model.dart';
import 'package:food_app/utils/log_util.dart';
import 'package:food_app/utils/my_application.dart';
import 'package:food_app/utils/printer_dummy.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderDetailBottomSheet extends StatefulWidget {
  Order order;

  OrderDetailBottomSheet(this.order);

  @override
  _OrderDetailBottomSheetState createState() => _OrderDetailBottomSheetState();
}

class _OrderDetailBottomSheetState extends State<OrderDetailBottomSheet> {
  late SharedPreferences sharedPreferences;
  String? bearerKey;
  Order updatedOrder = new Order();
  int? orderType = 0;
  String? storeName;

  @override
  void initState() {
    initVar();
    super.initState();
  }

  Future<void> initVar() async {
    updatedOrder = widget.order;
    sharedPreferences = await SharedPreferences.getInstance();
    bearerKey = sharedPreferences.getString(valueShared_BEARER_KEY);
    getStoredta(bearerKey);
  }

  Future<void> getStoredta(String? bearerKey) async {
    try {
      String? storeID = sharedPreferences.getString(valueShared_STORE_KEY);
      final result = await ApiRepo().getStoreData(bearerKey!, storeID!);

      if (result != null) {
        Store store = result;
        print("NAme " + store.name.toString());
        storeName = store.name.toString();
      } else {
        String errorMessage = result.mess ?? "Unknown error";
        showSnackbar("Error", errorMessage);
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }

  Future<void> getOrders(String? bearerKey, bool orderStatus) async {
    // var jsonData = widget.order.toJson();
    Map<String, dynamic> jsonData = {
      "order_status": orderStatus ? 2 : 1,
      "approval_status": orderStatus ? 2 : 3,
    };

    print("OrderStausUpdate 1 " + jsonData!.toString());
    //  jsonData['approval_status'] = orderStatus ? 2 : 3;
    print("data json" + jsonData.toString());
    try {
      print("DataBearerKEy " + bearerKey!);

      final result = await ApiRepo()
          .orderAcceptDecline(bearerKey!, jsonData, widget.order.id);
      // Log.loga(title, "LoginData :: result >>>>> ${result?.toJson()}");
      print("ResultData Get " + result.toString());

      if (result != null) {
        //final List<Order> orders = Order.fromJsonList(jsonEncode(result));
        setState(() {
          print("OrderSuccessfull " + result.toString());
          updatedOrder = result;
          app.appController.updateOrder(result);
          // getOrderAll(bearerKey, false);
          if (orderStatus) {
            orderType = 1;
          } else {
            orderType = 2;
          }
          // Navigator.of(context).pop();
        });
        // Handle navigation or success here
      } else {
        showSnackbar("Error", " error");
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      showSnackbar("Api Error", "An error occurred: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime startTime = DateTime.parse(
        widget.order.createdAt != null ? widget.order.createdAt! : "");
    DateTime endTime = startTime.add(Duration(minutes: 30));
    String formattedEnd = DateFormat('hh:mm a').format(endTime);

    DateTime newTime = startTime.add(Duration(minutes: 30));

    String orderTime = DateFormat('dd MMM, yyyy - hh:mm a').format(newTime);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Header
          Row(
            children: [
              widget.order.orderType == 1
                  ? CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.green,
                      child: SvgPicture.asset(
                        'assets/images/ic_pickup.svg',
                        height: 14,
                        width: 14,
                        color: Colors.white, // Optional: to tint the SVG
                      ),
                    )
                  : CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.green,
                      child: SvgPicture.asset(
                        'assets/images/ic_delivery.svg',
                        height: 14,
                        width: 14,
                        color: Colors.white, // Optional: to tint the SVG
                      ),
                    ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.order.orderType == 1
                      ? widget.order.shipping_address != null
                          ? widget.order.shipping_address!.line1! +
                              " , " +
                              widget.order.shipping_address!.city!
                          : ""
                      : "",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
              Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/clock.svg',
                    height: 16,
                    width: 16,
                    color: Colors.black, // Optional: to tint the SVG
                  ),
                  SizedBox(
                    width: 4,
                  ),
                  Text(
                    formattedEnd,
                    style: TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Order info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: "Order Number : ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors
                              .black, // Ensure the color is set for visibility
                        ),
                      ),
                      TextSpan(
                        text: "${widget.order.id}",
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8),
              Flexible(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: "Contact : ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: widget.order.shipping_address?.phone ?? "",
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            "${widget.order.shipping_address != null ? widget.order.shipping_address!.customer_name : ""}",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Flexible(
            child: RichText(
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.right,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: widget.order.orderType == 1
                        ? "Order Time : "
                        : "Delivery Time : ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: orderTime,
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 4),

          /*  Text(
            buildTaxSummaryText(widget.order),
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),*/

          // Order items
          SizedBox(
              height: 250,
              child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.order.items!.length!,
                  itemBuilder: (context, index) {
                    final order = widget.order.items![index];
                    return Container(
                      child: _orderItem(
                          order != null ? order.productName!.toString() : "",
                          order != null ? order.unitPrice!.toString() : "",
                          order,
                          note: order.note),
                    );
                  })),

          // Total
          Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange[400],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Gesamt:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black),
                  ),
                  Text(
                    "${widget.order.payment != null ? widget.order.payment!.amount!.toString() : "0"} €",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black),
                  ),
                ],
              )),
          const SizedBox(height: 12),
          // Action Buttons
          _buildActionButtons(
              context,
              widget.order.approvalStatus != null
                  ? widget.order.approvalStatus!
                  : 0)
          /*   Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionButton(context, Icons.check, "Accept", Colors.green),
                  _actionButton(context, Icons.close, "Decline", Colors.orange),
                ],
              )*/
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, int approvalStatus) {
    if (orderType == 0) {
      if (approvalStatus == 1) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _actionButton(context, Icons.check, "Accept", Colors.green),
            _actionButton(context, Icons.close, "Decline", Colors.orange[400]!),
          ],
        );
      } else if (approvalStatus == 2) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Order Accepted",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.green[400])),
            SizedBox(
              height: 10,
            ),
            CustomButton(
              onPressed: () {
                //printData(widget.order);
                printData(updatedOrder);
              },
              myText: "Print",
              color: Colors.green[400]!,
              textColor: Colors.white,
              fontSize: 17,
              fontWeigt: FontWeight.w700,
            ),
          ],
        );
      } else if (approvalStatus == 3) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Order Decline",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red[400]!)),
            SizedBox(
              height: 3,
            ),
            CustomButton(
              onPressed: () {
                printData(updatedOrder);
              },
              myText: "Print",
              color: Colors.green[400]!,
              textColor: Colors.white,
              fontSize: 17,
              fontWeigt: FontWeight.w700,
            ),
          ],
        );
      } else {
        return SizedBox.shrink(); // empty widget for any other status
      }
    } else {
      if (orderType == 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Order Accepted",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 3,
            ),
            CustomButton(
              onPressed: () {
                printData(updatedOrder);
              },
              myText: "Print",
              color: Colors.green[400]!,
              textColor: Colors.white,
              fontSize: 17,
              fontWeigt: FontWeight.w700,
            ),
          ],
        );
      } else if (orderType == 2) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Order Decline",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 3,
            ),
            CustomButton(
              onPressed: () {
                printData(updatedOrder);
              },
              myText: "Print",
              color: Colors.green[400]!,
              textColor: Colors.white,
              fontSize: 17,
              fontWeigt: FontWeight.w700,
            ),
          ],
        );
      } else {
        return SizedBox.shrink(); // empty widget for any other status
      }
    }
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
                  '${item.quantity!} $title',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 3, // This prevents wrapping
                ),
              ),
              Text(
                '€ ${(item.unitPrice! * item.quantity!).toStringAsFixed(1)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
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
                  "${item.variant!.name!}",
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  " [${item.variant!.price} €]",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          if (note!.isNotEmpty)
            Text(
              "+ $note",
              style: const TextStyle(color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _actionButton(
      BuildContext context, IconData icon, String label, Color color) {
    return GestureDetector(
        onTap: () {
          if (label == "Accept") {
            getOrders(bearerKey, true);
            print("IpAddress Called");
          } else if (label == "Decline") {
            // Navigator.of(context).pop();
            getOrders(bearerKey, false);
          }
        },
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              radius: 24,
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ));
  }

  void printData(Order order) {
/*    String itemDetails = updatedOrder.items?.map((item) {
          return "${item.productName ?? "Item"} x${item.quantity} - €${item.unitPrice?.toStringAsFixed(2) ?? "0.00"}";
        }).join("\n") ??
        "No items";

    print("ItemsProdyct "+itemDetails);
    String printMessage = "Order ID: ${updatedOrder.id}\n"
        "Amount: €${updatedOrder.invoice != null ? updatedOrder.invoice?.totalAmount?.toStringAsFixed(2) : "0" ?? "0.00"}\n"
        "Items:\n$itemDetails";
    print("printMessage "+printMessage);

  String dummyPrint="Food App dummy test to check the print";*/

    PrinterHelper.printTestFromSavedIp(
        context: context, order: order, store: storeName);
    //Navigator.of(context).pop();
  }

/*  Future<void> _printTest() async {
    final profile = await CapabilityProfile.load();
    final printer = NetworkPrinter(PaperSize.mm80, profile);
    final ip = _ipControllers[_selectedIpIndex].text;

    final result = await printer.connect(ip, port: 9100);

    if (result == PosPrintResult.success) {
      printer.setStyles(PosStyles(align: PosAlign.center));
      printer.text(
        'Hello from Flutter!',
        styles: PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
      printer.cut();
      printer.disconnect();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print success!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to print: $result')),
      );
    }
  }*/

  Future<void> getOrderAll(String? bearerKey, bool orderType) async {
    try {
      DateTime formatted = DateTime.now();
      String date = DateFormat('yyyy-MM-dd').format(formatted);
      final Map<String, dynamic> data = {
        "store_id": 4,
        "target_date": date,
        "limit": 0,
        "offset": 0,
      };
      final result = await ApiRepo().orderGetApiFilter(bearerKey!, data);
      // Log.loga(title, "LoginData :: result >>>>> ${result?.toJson()}");

      if (result.isNotEmpty && result.first.code == null) {
        setState(() {
          app.appController.setOrders(result);
        });
      } else {
        /* String errorMessage = result.isNotEmpty
            ? result.first.mess ?? "Unknown error"
            : "No data returned";
        showSnackbar("Error", errorMessage);*/
      }
    } catch (e) {
      Log.loga(title, "Login Api:: e >>>>> $e");
      // showSnackbar("Api Error", "An error occurred: $e");
    }
  }

  String buildTaxSummaryText(Order order) {
    print("OrderSummary " + order.taxSummary.toString());
    if (order.taxSummary != null && order.taxSummary!.isNotEmpty) {
      return order.taxSummary!.map((tax) {
        final rate = tax.taxRate?.toStringAsFixed(1) ?? "0.0";
        final amount = tax.taxAmount?.toStringAsFixed(2) ?? "0.00";
        return 'Tax ($rate%): EUR $amount';
      }).join('\n');
    } else {
      return "No tax summary to print for this order";
    }
  }
}
