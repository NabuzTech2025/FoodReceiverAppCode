import 'package:food_app/models/order_history_response_model.dart';
import 'package:food_app/models/order_model.dart';
import 'package:get/get.dart';

import '../models/ShippingAddress.dart';
import 'package:food_app/models/order_history_response_model.dart' as History;
import 'package:food_app/models/order_model.dart' as OrderModel;
final title = "AppController";

class AppController extends GetxController {
  final _isLoading = false.obs;

  void setLoading(bool show) {
    _isLoading.value = show;
  }

  bool get isLoading => _isLoading.value;
  var _selectedTabIndex = 0.obs;

  int get selectedTabIndex => _selectedTabIndex.value;

  RxInt get selectedTabIndexRx => _selectedTabIndex;

  var _reportRefreshTrigger = 0.obs;

  RxInt get reportRefreshTrigger => _reportRefreshTrigger;

  void onTabChanged(int index) {
    _selectedTabIndex.value = index;
    print("AppController: Tab changed to $index");

    if (index == 1) {
      _reportRefreshTrigger.value++;
      print("Report refresh triggered: ${_reportRefreshTrigger.value}");
    }
  }

  var _ordersList = <Order>[].obs;

  List<Order> get orderList => _ordersList.value;

  Future<void> setOrders(List<Order>? listOrders) async {
    if (listOrders == null || listOrders.isEmpty) {
      return;
    }

    _ordersList.value.clear();
    _ordersList.assignAll(listOrders);
    _ordersList.refresh();

    if (searchResultOrder.isNotEmpty) {
      searchResultOrder.clear();
    }
    searchResultOrder.assignAll(listOrders);

    onSetPendingOrder(listOrders.where((o) => o.approvalStatus == 1).length);
  }

  var searchResultOrder = <Order>[].obs;

  // ✅ Enhanced search function with multiple criteria
  void filterSearchResultsTodo(String query) {
    print("🔍 Filtering with query: '$query'");

    if (query.isEmpty) {
      // ✅ Empty query - show all orders sorted by ID
      searchResultOrder.assignAll(
        _ordersList..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0)), // Latest first
      );
      print("✅ Showing all ${searchResultOrder.length} orders");
    } else {
      final lowerQuery = query.toLowerCase();
      print("🔍 Searching for: '$lowerQuery'");

      final filteredOrders = _ordersList.where((order) {
        // ✅ 1. Search in Order ID
        final orderId = order.id?.toString().toLowerCase() ?? '';
        final matchesOrderId = orderId.contains(lowerQuery);

        // ✅ 2. Search in Customer Name
        final customerName = order.shipping_address?.customer_name?.toLowerCase() ?? '';
        final matchesCustomerName = customerName.contains(lowerQuery);

        // ✅ 3. Search in Customer Phone/Mobile
        final customerPhone = order.shipping_address?.phone?.toLowerCase() ?? '';
        final matchesPhone = customerPhone.contains(lowerQuery);

        // ✅ 4. Search in ZIP code
        final zipCode = order.shipping_address?.zip?.toString().toLowerCase() ?? '';
        final matchesZip = zipCode.contains(lowerQuery);

        // ✅ 5. Search in Address (line1, city)
        final addressLine1 = order.shipping_address?.line1?.toLowerCase() ?? '';
        final city = order.shipping_address?.city?.toLowerCase() ?? '';
        final matchesAddress = addressLine1.contains(lowerQuery) || city.contains(lowerQuery);

        // ✅ 6. Search in order items (product name, variant name, note)
        final matchesItems = order.items?.any((item) =>
        (item.productName?.toLowerCase().contains(lowerQuery) ?? false) ||
            (item.variantName?.toLowerCase().contains(lowerQuery) ?? false) ||
            (item.note?.toLowerCase().contains(lowerQuery) ?? false)
        ) ?? false;

        final isMatch = matchesOrderId ||
            matchesCustomerName ||
            matchesPhone ||
            matchesZip ||
            matchesAddress ||
            matchesItems;

        // ✅ Debug logging for each order
        if (isMatch) {
          print("✅ Match found - Order ID: ${order.id}, Customer: $customerName, Phone: $customerPhone, ZIP: $zipCode");
        }

        return isMatch;
      }).toList();

      // ✅ Sort filtered results (latest first)
      filteredOrders.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

      searchResultOrder.assignAll(filteredOrders);

      print("✅ Search completed. Found ${searchResultOrder.length} matching orders out of ${_ordersList.length} total orders");
    }

    // Force UI update
    searchResultOrder.refresh();
  }

  // ✅ Method to clear search and show all orders
  void clearSearch() {
    searchResultOrder.assignAll(
      _ordersList..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0)),
    );
    searchResultOrder.refresh();
    print("🧹 Search cleared, showing all ${searchResultOrder.length} orders");
  }

  void clearOrders() {
    print("🧹 Clearing all orders for new date");
    _ordersList.clear();
    searchResultOrder.clear();
    _pendingOrders.value = 0;
    _ordersList.refresh();
    searchResultOrder.refresh();
    print("✅ All orders cleared successfully");
  }

  Future<void> addNewOrder(Order result) async {
    try {
      print("🆕 Adding new order: ID ${result.id}");

      bool existsInMainList = _ordersList.any((order) => order.id == result.id);
      if (existsInMainList) {
        print("⚠️ Order ${result.id} already exists in main list, skipping add");
        return;
      }

      bool existsInSearchList = searchResultOrder.any((order) => order.id == result.id);
      if (existsInSearchList) {
        print("⚠️ Order ${result.id} already exists in search list, skipping add");
        return;
      }

      print("✅ Order ${result.id} is new, adding to lists");

      _ordersList.insert(0, result);
      _ordersList.value = [..._ordersList];

      searchResultOrder.insert(0, result);
      searchResultOrder.value = [...searchResultOrder];

      onSetPendingOrder(searchResultOrder.where((o) => o.approvalStatus == 1).length);

      print("✅ Order ${result.id} added successfully");
      print("📊 Total orders now: ${_ordersList.length}");

    } catch (e) {
      print("❌ Error adding new order: $e");
    }
  }

  Future<void> updateOrder(Order result) async {
    try {
      print("🔄 Updating order: ID ${result.id}");

      int index = _ordersList.indexWhere((order) => order.id == result.id);
      if (index != -1) {
        _ordersList[index] = result;
        _ordersList.value = [..._ordersList];
        print("✅ Order ${result.id} updated in main list at index $index");
      } else {
        print("⚠️ Order ${result.id} not found in main list for update");
      }

      int searchIndex = searchResultOrder.indexWhere((order) => order.id == result.id);
      if (searchIndex != -1) {
        searchResultOrder[searchIndex] = result;
        searchResultOrder.value = [...searchResultOrder];
        print("✅ Order ${result.id} updated in search list at index $searchIndex");
      } else {
        print("⚠️ Order ${result.id} not found in search list for update");
      }

      onSetPendingOrder(searchResultOrder.where((o) => o.approvalStatus == 1).length);

    } catch (e) {
      print("❌ Error updating order: $e");
    }
  }

  var _pendingOrders = 0.obs;

  int get getPendingOrder => _pendingOrders.value;

  void onSetPendingOrder(int index) {
    _pendingOrders.value = index;
  }

  void clearOnLogout() {
    _ordersList.clear();
    searchResultOrder.clear();
    _pendingOrders.value = 0;
    _selectedTabIndex.value = 0;
    _reportRefreshTrigger.value = 0;
    _isLoading.value = false;
  }

  void triggerReportRefresh() {
    _reportRefreshTrigger.value++;
    print("Manual report refresh triggered: ${_reportRefreshTrigger.value}");
  }

  void removeDuplicateOrders() {
    try {
      print("🧹 Removing duplicate orders...");

      Map<int, Order> uniqueOrders = {};
      for (var order in _ordersList) {
        if (order.id != null) {
          uniqueOrders[order.id!] = order;
        }
      }

      _ordersList.value = uniqueOrders.values.toList();

      Map<int, Order> uniqueSearchOrders = {};
      for (var order in searchResultOrder) {
        if (order.id != null) {
          uniqueSearchOrders[order.id!] = order;
        }
      }

      searchResultOrder.value = uniqueSearchOrders.values.toList();

      print("✅ Duplicates removed. Orders count: ${_ordersList.length}");

    } catch (e) {
      print("❌ Error removing duplicates: $e");
    }
  }

  void debugPrintOrders() {
    print("📋 === CURRENT ORDERS DEBUG ===");
    print("Main list count: ${_ordersList.length}");
    print("Search list count: ${searchResultOrder.length}");

    for (int i = 0; i < _ordersList.length; i++) {
      print("Main[$i]: ID ${_ordersList[i].id}");
    }

    for (int i = 0; i < searchResultOrder.length; i++) {
      print("Search[$i]: ID ${searchResultOrder[i].id}");
    }
    print("📋 === END DEBUG ===");
  }

  // Add this method in AppController class
  // ✅ FIXED: Use History models directly instead of converting to OrderModel
  var _historyOrdersList = <History.orderHistoryResponseModel>[].obs;

  List<History.orderHistoryResponseModel> get historyOrdersList => _historyOrdersList.value;

  void setHistoryOrders(List<History.orderHistoryResponseModel> historyOrders) {
    print("📋 Setting ${historyOrders.length} history orders");

    _historyOrdersList.clear();
    _historyOrdersList.assignAll(historyOrders);
    _historyOrdersList.refresh();

    print("✅ History orders set: ${_historyOrdersList.length}");
  }

  History.orderHistoryResponseModel? getHistoryOrderByIndex(int index) {
    if (index >= 0 && index < _historyOrdersList.length) {
      return _historyOrdersList[index];
    }
    return null;
  }

  // ✅ Helper methods to get data from history orders in a consistent way
  String? getHistoryOrderCustomerName(int index) {
    final order = getHistoryOrderByIndex(index);
    return order?.shippingAddress?.customerName;
  }

  String? getHistoryOrderPhone(int index) {
    final order = getHistoryOrderByIndex(index);
    return order?.shippingAddress?.phone;
  }

  String? getHistoryOrderAddress(int index) {
    final order = getHistoryOrderByIndex(index);
    if (order?.shippingAddress != null) {
      final addr = order!.shippingAddress!;
      return "${addr.line1 ?? ''}, ${addr.city ?? ''}, ${addr.zip ?? ''}".trim();
    }
    return null;
  }

  double? getHistoryOrderTotal(int index) {
    final order = getHistoryOrderByIndex(index);
    return order?.invoice?.totalAmount;
  }

  String? getHistoryOrderPaymentMethod(int index) {
    final order = getHistoryOrderByIndex(index);
    return order?.payment?.paymentMethod;
  }

  String? getHistoryOrderStatus(int index) {
    final order = getHistoryOrderByIndex(index);
    switch (order?.approvalStatus) {
      case 0:
        return "Pending";
      case 1:
        return "Approved";
      case 2:
        return "Rejected";
      default:
        return "Unknown";
    }
  }

  List<History.Items>? getHistoryOrderItems(int index) {
    final order = getHistoryOrderByIndex(index);
    return order?.items;
  }





}
