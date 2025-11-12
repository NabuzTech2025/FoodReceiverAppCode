import 'package:food_app/models/order_model.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:food_app/models/order_history_response_model.dart' as History;

import '../models/reservation/get_user_reservation_details.dart';
const title = "AppController";

class AppController extends GetxController {
  final _isLoading = false.obs;

  void setLoading(bool show) {
    _isLoading.value = show;
  }

  bool get isLoading => _isLoading.value;
  final _selectedTabIndex = 0.obs;

  int get selectedTabIndex => _selectedTabIndex.value;

  RxInt get selectedTabIndexRx => _selectedTabIndex;

  final _reportRefreshTrigger = 0.obs;

  RxInt get reportRefreshTrigger => _reportRefreshTrigger;

  void onTabChanged(int index) {
    _selectedTabIndex.value = index;
    print("AppController: Tab changed to $index");

    if (index == 1) {
      _reportRefreshTrigger.value++;
      print("Report refresh triggered: ${_reportRefreshTrigger.value}");
    }
  }

  final _ordersList = <Order>[].obs;

  List<Order> get orderList => _ordersList.value;

  var searchResultOrder = <Order>[].obs;

  Future<void> forceSetAllOrders(List<Order> orders) async {
    print("🔄 Force setting all orders - Received: ${orders.length}");

    // Clear everything first
    _ordersList.clear();
    searchResultOrder.clear();

    // Add all orders
    _ordersList.assignAll(orders);

    // Sort by ID descending (newest first)
    _ordersList.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

    // Update search results with all orders
    searchResultOrder.assignAll(_ordersList);

    // Refresh observables
    _ordersList.refresh();
    searchResultOrder.refresh();

    // Update pending count
    int pendingCount = _ordersList
        .where((o) => o.approvalStatus == 1)
        .length;
    onSetPendingOrder(pendingCount);

    print("✅ Force set completed - Total orders: ${_ordersList.length}");

    // Debug print order IDs
    print("📋 Order IDs: ${_ordersList.take(5).map((o) => o.id).toList()}...");
  }

// Also modify the existing setOrders method to be more explicit about merge vs replace:

  Future<void> setOrders(List<Order>? listOrders,
      {bool forceReplace = false}) async {
    if (listOrders == null) {
      print("⚠️ setOrders called with null list");
      return;
    }

    if (listOrders.isEmpty) {
      print("📋 API returned empty order list");
      // Don't clear existing orders unless explicitly told to
      if (forceReplace) {
        _ordersList.clear();
        searchResultOrder.clear();
        _ordersList.refresh();
        searchResultOrder.refresh();
      }
      return;
    }

    print("📦 Setting orders - Received: ${listOrders
        .length} orders, forceReplace: $forceReplace");

    if (forceReplace) {
      // Complete replacement
      print("🔄 Force replacing all orders");
      _ordersList.clear();
      _ordersList.assignAll(listOrders);

      searchResultOrder.clear();
      searchResultOrder.assignAll(listOrders);
    } else {
      // Merge new orders with existing ones (avoid duplicates)
      Set<int> existingIds = _ordersList.map((order) => order.id ?? 0).toSet();

      List<Order> newOrders = listOrders.where((order) =>
      order.id != null && !existingIds.contains(order.id!)
      ).toList();

      if (newOrders.isNotEmpty) {
        // Add new orders at the beginning
        _ordersList.insertAll(0, newOrders);
        searchResultOrder.insertAll(0, newOrders);
        print("➕ Added ${newOrders.length} new orders");
      }
    }

    // Sort both lists
    _ordersList.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    searchResultOrder.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

    // Refresh observables
    _ordersList.refresh();
    searchResultOrder.refresh();

    // Update pending count
    int pendingCount = _ordersList
        .where((o) => o.approvalStatus == 1)
        .length;
    onSetPendingOrder(pendingCount);

    print("✅ setOrders completed - Total: ${_ordersList
        .length}, Search: ${searchResultOrder.length}");
  }

  void filterSearchResultsTodo(String query) {
    print("🔍 Filtering with query: '$query'");
    print("📊 Total orders available: ${_ordersList.length}");

    if (query.isEmpty || query
        .trim()
        .isEmpty) {
      // Show all orders when search is empty
      searchResultOrder.assignAll(_ordersList);
      searchResultOrder.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      print("✅ Showing all ${searchResultOrder.length} orders");
    } else {
      final lowerQuery = query.toLowerCase().trim();

      final filteredOrders = _ordersList.where((order) {
        // Search in Order ID
        final orderId = order.id?.toString().toLowerCase() ?? '';
        if (orderId.contains(lowerQuery)) return true;

        // Search in Customer Name (both regular and guest)
        final customerName = order.shipping_address?.customer_name
            ?.toLowerCase() ??
            order.guestShippingJson?.customerName?.toLowerCase() ?? '';
        if (customerName.contains(lowerQuery)) return true;

        // Search in Phone (both regular and guest)
        final phone = order.shipping_address?.phone?.toLowerCase() ??
            order.guestShippingJson?.phone?.toLowerCase() ?? '';
        if (phone.contains(lowerQuery)) return true;

        // Search in ZIP (both regular and guest)
        final zip = order.shipping_address?.zip?.toString().toLowerCase() ??
            order.guestShippingJson?.zip?.toString().toLowerCase() ?? '';
        if (zip.contains(lowerQuery)) return true;

        // Search in Address (both regular and guest)
        final line1 = order.shipping_address?.line1?.toLowerCase() ??
            order.guestShippingJson?.line1?.toLowerCase() ?? '';
        final city = order.shipping_address?.city?.toLowerCase() ??
            order.guestShippingJson?.city?.toLowerCase() ?? '';
        if (line1.contains(lowerQuery) || city.contains(lowerQuery))
          return true;

        // Search in order items
        if (order.items?.any((item) =>
        (item.productName?.toLowerCase().contains(lowerQuery) ?? false) ||
            (item.variantName?.toLowerCase().contains(lowerQuery) ?? false) ||
            (item.note?.toLowerCase().contains(lowerQuery) ?? false)
        ) ?? false) {
          return true;
        }

        return false;
      }).toList();

      // Sort filtered results
      filteredOrders.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

      searchResultOrder.assignAll(filteredOrders);
      print("✅ Search completed. Found ${searchResultOrder
          .length} matching orders");
    }

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
        print(
            "⚠️ Order ${result.id} already exists in main list, skipping add");
        return;
      }
      bool existsInSearchList = searchResultOrder.any((order) =>
      order.id == result.id);
      if (existsInSearchList) {
        print("⚠️ Order ${result
            .id} already exists in search list, skipping add");
        return;
      }

      print("✅ Order ${result.id} is new, adding to lists");

      _ordersList.insert(0, result);
      _ordersList.value = [..._ordersList];

      searchResultOrder.insert(0, result);
      searchResultOrder.value = [...searchResultOrder];

      onSetPendingOrder(_ordersList
          .where((o) => o.approvalStatus == 1)
          .length);
      print("✅ Order ${result.id} added successfully. Total: ${_ordersList
          .length}");

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

      int searchIndex = searchResultOrder.indexWhere((order) =>
      order.id == result.id);
      if (searchIndex != -1) {
        searchResultOrder[searchIndex] = result;
        searchResultOrder.value = [...searchResultOrder];
        print("✅ Order ${result
            .id} updated in search list at index $searchIndex");
      } else {
        print("⚠️ Order ${result.id} not found in search list for update");
      }

      onSetPendingOrder(searchResultOrder
          .where((o) => o.approvalStatus == 1)
          .length);
    } catch (e) {
      print("❌ Error updating order: $e");
    }
  }

  final _pendingOrders = 0.obs;
  final _pendingReservations = 0.obs;

  int get getPendingOrder => _pendingOrders.value;

  int get getPendingReservations => _pendingReservations.value;

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
    clearReservationsOnLogout();
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

  final _historyOrdersList = <History.orderHistoryResponseModel>[].obs;

  List<History.orderHistoryResponseModel> get historyOrdersList =>
      _historyOrdersList.value;

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
      return "${addr.line1 ?? ''}, ${addr.city ?? ''}, ${addr.zip ?? ''}"
          .trim();
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

// In AppController.dart, add reservation methods:

  final _reservationsList = <GetUserReservationDetailsResponseModel>[].obs;
  var searchResultReservation = <GetUserReservationDetailsResponseModel>[].obs;

  List<GetUserReservationDetailsResponseModel> get reservationsList =>
      _reservationsList.value;

  void setReservations(
      List<GetUserReservationDetailsResponseModel> reservations) {
    _reservationsList.clear();
    _reservationsList.assignAll(reservations);

    // Initialize search results with all reservations
    searchResultReservation.clear();
    searchResultReservation.assignAll(reservations);

    _reservationsList.refresh();
    searchResultReservation.refresh();

    int pendingCount = reservations.where((reservation) =>
    reservation.status?.toLowerCase() == 'pending').length;
    _pendingReservations.value = pendingCount;

    print(
        "Set ${reservations.length} total reservations, $pendingCount pending");
  }

  void addNewReservation(GetUserReservationDetailsResponseModel reservation) {
    bool exists = _reservationsList.any((r) => r.id == reservation.id);
    if (!exists) {
      _reservationsList.insert(0, reservation);
      _reservationsList.refresh();

      // ADD THIS: Also update search results immediately
      searchResultReservation.insert(0, reservation);
      searchResultReservation.refresh();

      int pendingCount = _reservationsList.where((r) =>
      r.status?.toLowerCase() == 'pending').length;
      _pendingReservations.value = pendingCount;

      print("✅ New reservation ${reservation
          .id} added and search results updated");
    }
  }

  void updateReservation(GetUserReservationDetailsResponseModel reservation) {
    int index = _reservationsList.indexWhere((r) => r.id == reservation.id);
    if (index != -1) {
      _reservationsList[index] = reservation;
      _reservationsList.refresh();
      int pendingCount = _reservationsList.where((r) =>
      r.status?.toLowerCase() == 'pending').length;
      _pendingReservations.value = pendingCount;
    }
  }

  void clearReservationSearch() {
    searchResultReservation.assignAll(_reservationsList);
    searchResultReservation.refresh();
    print("🧹 Reservation search cleared, showing all ${searchResultReservation
        .length} reservations");
  }

  void clearReservationsOnLogout() {
    _reservationsList.clear();
    searchResultReservation.clear();
    _pendingReservations.value = 0;
  }

  void filterSearchResultsReservation(String query) {
    print("🔍 Filtering reservations with query: '$query'");
    print("📊 Total reservations available: ${_reservationsList.length}");

    if (query.isEmpty || query
        .trim()
        .isEmpty) {
      // Show all reservations when search is empty
      searchResultReservation.assignAll(_reservationsList);
      print("✅ Showing all ${searchResultReservation.length} reservations");
    } else {
      final lowerQuery = query.toLowerCase().trim();

      final filteredReservations = _reservationsList.where((reservation) {
        // Search in Reservation ID
        final reservationId = reservation.id?.toString().toLowerCase() ?? '';
        if (reservationId.contains(lowerQuery)) return true;

        // Search in Customer Name
        final customerName = reservation.customerName?.toLowerCase() ?? '';
        if (customerName.contains(lowerQuery)) return true;

        // Search in Customer Phone
        final phone = reservation.customerPhone?.toLowerCase() ?? '';
        if (phone.contains(lowerQuery)) return true;

        // Search in Guest Count
        final guestCount = reservation.guestCount?.toString().toLowerCase() ??
            '';
        if (guestCount.contains(lowerQuery)) return true;

        // Search in Status
        final status = reservation.status?.toLowerCase() ?? '';
        if (status.contains(lowerQuery)) return true;

        return false;
      }).toList();

      searchResultReservation.assignAll(filteredReservations);
      print("✅ Search completed. Found ${searchResultReservation
          .length} matching reservations");
    }

    searchResultReservation.refresh();
  }


  List<GetUserReservationDetailsResponseModel> getFilteredReservations(
      String? selectedDate) {
    DateTime today = DateTime.now();
    String todayString = DateFormat('yyyy-MM-dd').format(today);

    // Use search results instead of main list
    return searchResultReservation.where((reservation) {
      String status = reservation.status?.toLowerCase() ?? '';

      if (status == 'pending') {
        // Pending reservations show regardless of date
        return true;
      } else if (status == 'cancelled' || status == 'booked') {
        // Cancelled and booked only show for current date or selected date
        String targetDate = selectedDate ?? todayString;

        // Check reservation date (use reservedFor field if available, otherwise createdAt)
        String? dateToCheck = reservation.reservedFor ?? reservation.createdAt;

        if (dateToCheck != null) {
          try {
            DateTime reservationDate = DateTime.parse(dateToCheck);
            String reservationDateString = DateFormat('yyyy-MM-dd').format(
                reservationDate);
            return reservationDateString == targetDate;
          } catch (e) {
            print("Error parsing reservation date: $e");
            return false;
          }
        }
        return false;
      }

      // For any other status, show all
      return true;
    }).toList();
  }

// Also add this method to get filtered count
  int getFilteredReservationsCount(String? selectedDate) {
    return getFilteredReservations(selectedDate).length;
  }

  var triggerAddReservation = false.obs;

  Function(String)? productsFilterCallback;
  Function(String)? categoryFilterCallback;

  void registerProductsFilter(Function(String) callback) {
    productsFilterCallback = callback;
    print("✅ Products filter callback registered");
  }

  void registerCategoryFilter(Function(String) callback) {
    categoryFilterCallback = callback;
    print("✅ Category filter callback registered");
  }

  void clearFilterCallbacks() {
    productsFilterCallback = null;
    categoryFilterCallback = null;
    print("🧹 Filter callbacks cleared");
  }
}