import 'package:food_app/models/order_model.dart';
import 'package:get/get.dart';

final title = "AppController";

class AppController extends GetxController {
  final _isLoading = false.obs;

  void setLoading(bool show) {
    _isLoading.value = show;
    // _isLoading(true);
  }

  bool get isLoading => _isLoading.value;
  var _selectedTabIndex = 0.obs;

  int get selectedTabIndex => _selectedTabIndex.value;

  // ✅ ADD THIS: Getter for reactive access
  RxInt get selectedTabIndexRx => _selectedTabIndex;

  // ✅ ADD THIS: Report refresh trigger
  var _reportRefreshTrigger = 0.obs;

  RxInt get reportRefreshTrigger => _reportRefreshTrigger;

  void onTabChanged(int index) {
    _selectedTabIndex.value = index;
    print("AppController: Tab changed to $index"); // Add this for debugging

    // ✅ ADD THIS: Trigger report refresh when Report tab is selected
    if (index == 1) { // Report tab index
      _reportRefreshTrigger.value++;
      print("Report refresh triggered: ${_reportRefreshTrigger.value}");
    }
  }

  var _ordersList = <Order>[].obs;

  List<Order> get orderList => _ordersList.value;

  Future<void> setOrders(List<Order>? listOrders) async {
    if (listOrders == null || listOrders.isEmpty) {
      return; // or handle it appropriately
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

  void filterSearchResultsTodo(String query) {
    if (query.isEmpty) {
      searchResultOrder.assignAll(
        _ordersList..sort((a, b) => a.id!.compareTo(b.id!)),
      );
    } else {
      final lowerQuery = query.toLowerCase();

      searchResultOrder.assignAll(
        _ordersList.where((order) {
          // Search in order ID
          final inOrderId =
          order.id.toString().toLowerCase().contains(lowerQuery);

          // Search in order items
          final inItems = order.items?.any((item) =>
          item.productName
              ?.toLowerCase()
              .contains(lowerQuery) ==
              true ||
              item.variantName?.toLowerCase().contains(lowerQuery) ==
                  true ||
              item.note?.toLowerCase().contains(lowerQuery) == true) ??
              false;

          return inOrderId || inItems;
        }).toList()
          ..sort((a, b) => a.id!.compareTo(b.id!)),
      );
    }
  }

  Future<void> addNewOrder(Order result) async {
    try {
      print("🆕 Adding new order: ID ${result.id}");

      // ✅ Step 1: Check if order already exists in _ordersList
      bool existsInMainList = _ordersList.any((order) => order.id == result.id);
      if (existsInMainList) {
        print("⚠️ Order ${result.id} already exists in main list, skipping add");
        return;
      }

      // ✅ Step 2: Check if order already exists in searchResultOrder
      bool existsInSearchList = searchResultOrder.any((order) => order.id == result.id);
      if (existsInSearchList) {
        print("⚠️ Order ${result.id} already exists in search list, skipping add");
        return;
      }

      // ✅ Step 3: Add to both lists only if it doesn't exist
      print("✅ Order ${result.id} is new, adding to lists");

      _ordersList.insert(0, result);
      _ordersList.value = [..._ordersList]; // Trigger reactivity

      searchResultOrder.insert(0, result);
      searchResultOrder.value = [...searchResultOrder]; // Trigger reactivity

      // ✅ Step 4: Update pending count
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

      // Find and update in _ordersList
      int index = _ordersList.indexWhere((order) => order.id == result.id);
      if (index != -1) {
        _ordersList[index] = result;
        _ordersList.value = [..._ordersList]; // Trigger reactivity
        print("✅ Order ${result.id} updated in main list at index $index");
      } else {
        print("⚠️ Order ${result.id} not found in main list for update");
      }

      // Find and update in searchResultOrder
      int searchIndex = searchResultOrder.indexWhere((order) => order.id == result.id);
      if (searchIndex != -1) {
        searchResultOrder[searchIndex] = result;
        searchResultOrder.value = [...searchResultOrder]; // Trigger reactivity
        print("✅ Order ${result.id} updated in search list at index $searchIndex");
      } else {
        print("⚠️ Order ${result.id} not found in search list for update");
      }

      // Update pending count
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
    _reportRefreshTrigger.value = 0; // ✅ ADD THIS: Reset refresh trigger
    // If needed, reset loading state as well
    _isLoading.value = false;
  }

  // ✅ ADD THIS: Manual method to trigger report refresh
  void triggerReportRefresh() {
    _reportRefreshTrigger.value++;
    print("Manual report refresh triggered: ${_reportRefreshTrigger.value}");
  }

  void removeDuplicateOrders() {
    try {
      print("🧹 Removing duplicate orders...");

      // Remove duplicates from main list
      Map<int, Order> uniqueOrders = {};
      for (var order in _ordersList) {
        if (order.id != null) {
          uniqueOrders[order.id!] = order;
        }
      }

      _ordersList.value = uniqueOrders.values.toList();

      // Remove duplicates from search list
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

  // ✅ NEW: Debug method to print current orders
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
}

