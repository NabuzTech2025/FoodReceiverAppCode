import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:food_app/models/order_history_response_model.dart';
import 'package:food_app/ui/OrderDetailEnglish.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../api/repository/api_repository.dart';
import '../models/order_model.dart';
import '../utils/my_application.dart';
import 'order_history_details.dart';

class OrderHistory extends StatefulWidget {
  final List<orderHistoryResponseModel> orders; // Data receive करें
  final String targetDate; // Date receive करें

  const OrderHistory({
    super.key,
    required this.orders,
    required this.targetDate,
  });

  @override
  State<OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<OrderHistory> {

  // Status के अनुसार icon return करें
  IconData getStatusIcon(int status) {
    switch (status) {
      case 1:
        return Icons.pending;
      case 2:
        return Icons.check_circle;
      case 3:
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  // Status के अनुसार color return करें
  Color getStatusColor(int status) {
    switch (status) {
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getApprovalStatusText(int? status) {
    switch (status) {
      case 1:
        return 'Pending';
      case 2:
        return 'Accepted';
      case 3:
        return 'Declined';
      default:
        return 'Unknown';
    }
  }

  Color getContainerColor(int? status) {
    switch (status) {
      case 2: // Accepted
        return Color(0xffEBFFF4);
      case 3: // Declined
        return Color(0xffFFEFEF);
      case 1: // Pending
        return Colors.white;
      default:
        return Colors.white;
    }
  }


  String getOrderTypeIcon(int? orderType) {
    switch (orderType) {
      case 1:
        return 'assets/images/ic_delivery.svg';
      case 2:
        return 'assets/images/ic_pickup.svg';
      case 3:
        return 'assets/images/ic_dine_in.svg'; // Assuming you have this
      default:
        return 'assets/images/ic_pickup.svg';
    }
  }

  String getOrderTypeText(int? orderType) {
    switch (orderType) {
      case 1:
        return 'Delivery';
      case 2:
        return 'Pickup';
      case 3:
        return 'Dine In';
      default:
        return 'Unknown';
    }
  }


  String formatAmount(double amount) {
    return NumberFormat('#,##0.00').format(amount);
  }

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      // appBar: AppBar(
      //   backgroundColor: Colors.white,
      //   title: Row(
      //    // mainAxisSize: MainAxisSize.min,
      //     children: [
      //       Text(
      //         DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.targetDate)),
      //         style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w400),
      //       ),
      //       Text(
      //         'order_details'.tr,
      //         style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 18),
      //       ),
      //     ],
      //   ),
      //   centerTitle: true,
      //   leading: IconButton(
      //     icon: Icon(Icons.arrow_back, color: Colors.black),
      //     onPressed: () => Navigator.pop(context),
      //   ),
      // ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'order_history'.tr,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500,fontSize: 20),
        ),
        centerTitle: true,
        leading: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: Text(
                DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.targetDate)),
                style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Text(
                  'Total Orders: ${widget.orders.length}',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: "Mulish",
                      color: Colors.black),
                ),
                // SizedBox(width: 10)
              ],
            ),
          ),
          if (widget.orders.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/empty.json', // Empty animation
                      width: 200,
                      height: 200,
                    ),
                    Text(
                      'No orders found for this date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )

          // Order list
          else
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(15),
                itemCount: widget.orders.length,
                itemBuilder: (context, index) {
                  final order = widget.orders[index];
                  String time = '';
                  if (order.createdAt != null) {
                    DateTime dateTime = DateTime.parse(order.createdAt!);
                    time = DateFormat('hh:mm a').format(dateTime);
                  }

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: getContainerColor(order.approvalStatus),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: order.approvalStatus == 2
                            ? Color(0xffC3F2D9)
                            : order.approvalStatus == 3
                            ? Color(0xffFFD0D0)
                            : Colors.grey.withOpacity(0.2),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                            Get.to(() =>OrderHistoryDetails(historyOrder: order,));
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.green,
                                      child: SvgPicture.asset(
                                        getOrderTypeIcon(order.orderType),
                                        height: 14,
                                        width: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getOrderTypeText(order.orderType),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            fontFamily: "Mulish-Regular",
                                          ),
                                        ),
                                        if (order.shippingAddress != null &&
                                            order.orderType == 1)
                                          Text(
                                            '${order.shippingAddress!.line1 ?? ''}, ${order.shippingAddress!.city ?? ''}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 11,
                                              fontFamily: "Mulish",
                                            ),
                                          ),
                                      ],
                                    )
                                  ],
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 20),
                                    SizedBox(width: 4),
                                    Text(
                                      time,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontFamily: "Mulish",
                                        fontSize: 10,
                                      ),
                                    )
                                  ],
                                )
                              ],
                            ),
                            SizedBox(height: 8),

                            // Customer info and order ID
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.5,
                                  child: Text(
                                    '${order.shippingAddress?.customerName ?? order.user?.username ?? "User"} / ${order.shippingAddress?.phone ?? "N/A"}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontFamily: "Mulish",
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      'Order ID: ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11,
                                        fontFamily: "Mulish",
                                      ),
                                    ),
                                    Text(
                                      '${order.id ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 11,
                                        fontFamily: "Mulish",
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Amount and status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '€${formatAmount(order.invoice?.totalAmount?.toDouble() ?? 0.0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontFamily: "Mulish",
                                    fontSize: 16,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      getApprovalStatusText(order.approvalStatus),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontFamily: "Mulish-Regular",
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: getStatusColor(order.approvalStatus ?? 0),
                                      child: Icon(
                                        getStatusIcon(order.approvalStatus ?? 0),
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}