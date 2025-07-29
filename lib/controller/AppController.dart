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
    _ordersList.insert(0, result);
    _ordersList.value = [..._ordersList];
    // Insert at index 0 in searchResultOrder and trigger rebuild
    searchResultOrder.value = [result, ...searchResultOrder];
  }

  Future<void> updateOrder(Order result) async {
    // Find index in _ordersList
    int index = _ordersList.indexWhere((order) => order.id == result.id);
    if (index != -1) {
      _ordersList[index] = result;
      _ordersList.value = [..._ordersList];
    }

    // Find index in searchResultOrder and update
    int searchIndex =
    searchResultOrder.indexWhere((order) => order.id == result.id);
    if (searchIndex != -1) {
      searchResultOrder[searchIndex] = result;
      searchResultOrder.value = [...searchResultOrder];
    }
    onSetPendingOrder(searchResultOrder.where((o) => o.approvalStatus == 1).length);
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
}