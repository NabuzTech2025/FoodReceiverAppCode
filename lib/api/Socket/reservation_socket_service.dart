import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../models/reservation/get_user_reservation_details.dart';
import '../api.dart';

class SocketReservationService extends GetxService {
  static SocketReservationService get instance => Get.find();

  IO.Socket? _socket;
  bool _isConnected = false;

  // Observable variables
  final RxList<GetUserReservationDetailsResponseModel> reservations = <GetUserReservationDetailsResponseModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString connectionStatus = 'Disconnected'.obs;

  // Callback functions for different events
  Function(Map<String, dynamic>)? onNewReservation;
  Function(Map<String, dynamic>)? onReservationUpdate;
  Function(Map<String, dynamic>)? onSalesUpdate;
  Function(Map<String, dynamic>)? onNewOrder;
  Function(Map<String, dynamic>)? onOrderUpdate;
  Function()? onConnected;
  Function()? onDisconnected;

  // Getters
  bool get isConnected => _isConnected;
  List<GetUserReservationDetailsResponseModel> get reservationsList => reservations;

  @override
  void onInit() {
    super.onInit();
    // Don't auto-connect here, wait for explicit connect call
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }

  // Get stored access token
  String? _getStoredToken() {
    try {
      var box = Hive.box('userBox');
      return box.get('access_token');
    } catch (e) {
      print('Error getting stored token: $e');
      return null;
    }
  }

  // Connect to Socket.IO server with dynamic storeId and driverId
  void connect(String accessToken, {required int storeId, int? driverId}) {
    if (_socket != null && _isConnected) {
      print('Socket already connected');
      return;
    }

    try {
      // Debug print to verify parameters
      print('🔌 Connecting to reservation socket with storeId: $storeId, driverId: $driverId');

      _socket = IO.io(Api.baseUrl,
          IO.OptionBuilder()
              .setPath('/ws-sio/socket.io')
              .setTransports(['websocket'])
              .setAuth({
            'token': 'Bearer $accessToken',
          })
              .disableAutoConnect()
              .build()
      );

      _setupSocketListeners(storeId, driverId);
      _socket!.connect();

      connectionStatus.value = 'Connecting...';
      print('Connecting to Reservation Socket.IO server...');

    } catch (e) {
      print('Error connecting to reservation socket: $e');
      connectionStatus.value = 'Connection Failed';
    }
  }

  // Setup Socket Event Listeners
  void _setupSocketListeners(int storeId, int? driverId) {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      print('✅ Connected to Reservation Socket.IO');
      _isConnected = true;
      connectionStatus.value = 'Connected';
      _joinRooms(storeId, driverId);
      onConnected?.call();
    });

    _socket!.onDisconnect((_) {
      print('❌ Disconnected from Reservation Socket.IO');
      _isConnected = false;
      connectionStatus.value = 'Disconnected';
      onDisconnected?.call();
    });

    _socket!.onConnectError((error) {
      print('Connection Error: $error');
      connectionStatus.value = 'Connection Error';
    });

    // Room join confirmations
    _socket!.on('joined_store', (data) {
      print('✅ Joined Reservation store room: ${data['room']}');
    });

    _socket!.on('joined_sales_store', (data) {
      print('✅ Joined Reservation store sales room: ${data['room']}');
    });

    _socket!.on('joined_all_driver_sales', (data) {
      print('✅ Joined Reservation all drivers sales room: ${data['room']}');
    });

    _socket!.on('joined_driver_sales', (data) {
      print('✅ Joined Reservation specific driver room: ${data['room']}');
    });

    // Reservation events
    _socket!.on('new_reservation', (data) {
      print('📅 New reservation received:');
      print(data.toString());
      _handleNewReservation(data);
      if (data is Map<String, dynamic>) {
        onNewReservation?.call(data);
      }
    });

    _socket!.on('reservation_updated', (data) {
      print('✏️ Reservation updated:');
      print(data.toString());
      _handleReservationUpdate(data);
      if (data is Map<String, dynamic>) {
        onReservationUpdate?.call(data);
      }
    });

    // Order events
    _socket!.on('new_order', (data) {
      print('🆕 New order event:');
      print(data.toString());
      if (data is Map<String, dynamic>) {
        onNewOrder?.call(data);
      }
    });

    _socket!.on('order_updated', (data) {
      print('📝 Order update:');
      print(data.toString());
      if (data is Map<String, dynamic>) {
        onOrderUpdate?.call(data);
      }
    });

    // Sales events
    _socket!.on('sales_update', (data) {
      print('💰 Store sales update:');
      print(data.toString());
      if (data is Map<String, dynamic>) {
        onSalesUpdate?.call(data);
      }
    });

    _socket!.on('all_driver_sales_update', (data) {
      print('🚚 All driver sales update:');
      print(data.toString());
    });

    _socket!.on('driver_sales_update', (data) {
      print('👤 Specific driver sales update:');
      print(data.toString());
    });

    // Session control
    _socket!.on('force_logout', (data) {
      print('🚫 Force logout received:');
      print(data.toString());

      Get.snackbar(
        'Session Expired',
        data['msg'] ?? 'You have been logged out',
        snackPosition: SnackPosition.BOTTOM,
      );

      _handleForceLogout();
    });
  }

  // Join necessary rooms with dynamic IDs
  void _joinRooms(int storeId, int? driverId) {
    if (_socket == null || !_isConnected) return;

    try {
      // Join store room
      _socket!.emit('join_store', {'store_id': storeId});
      print('🏪 Joining reservation store room with ID: $storeId');

      // Join store sales room
      _socket!.emit('join_store_sales', {'store_id': storeId});
      print('💰 Joining reservation sales room with ID: $storeId');

      // Join all driver sales room
      _socket!.emit('join_all_driver_sales', {'store_id': storeId});
      print('🚚 Joining reservation all drivers sales room with ID: $storeId');

      // Join specific driver sales room (if driverId provided)
      if (driverId != null) {
        _socket!.emit('join_driver_sales', {
          'store_id': storeId,
          'driver_id': driverId,
        });
        print('👤 Joining reservation specific driver room with store_id: $storeId, driver_id: $driverId');
      }

    } catch (e) {
      print('Error joining reservation rooms: $e');
    }
  }

  // Handle new reservation
  void _handleNewReservation(dynamic data) {
    try {
      // Convert the socket data to your reservation model
      var newReservation = GetUserReservationDetailsResponseModel.fromJson(data);

      // Add to the list
      reservations.insert(0, newReservation);

      // Show notification
      Get.snackbar(
        'New Reservation',
        'New reservation received from ${newReservation.customerName}',
        snackPosition: SnackPosition.TOP,
      );

    } catch (e) {
      print('Error handling new reservation: $e');
    }
  }

  // Handle reservation update
  void _handleReservationUpdate(dynamic data) {
    try {
      var updatedReservation = GetUserReservationDetailsResponseModel.fromJson(data);

      // Find and update existing reservation
      int index = reservations.indexWhere((res) => res.id == updatedReservation.id);

      if (index != -1) {
        reservations[index] = updatedReservation;

        Get.snackbar(
          'Reservation Updated',
          'Reservation #${updatedReservation.id} has been updated',
          snackPosition: SnackPosition.TOP,
        );
      }

    } catch (e) {
      print('Error handling reservation update: $e');
    }
  }

  // Handle force logout
  void _handleForceLogout() {
    disconnect();
    _clearStoredData();

    // Navigate to login screen
    Get.offAllNamed('/login'); // Adjust route as per your app
  }

  // Clear stored data
  void _clearStoredData() {
    try {
      var box = Hive.box('userBox');
      box.delete('access_token');
      reservations.clear();
    } catch (e) {
      print('Error clearing stored data: $e');
    }
  }

  // Public method to connect with token (for backward compatibility)
  void connectWithToken(String token, {int? storeId, int? driverId}) {
    // Store token in Hive
    try {
      var box = Hive.box('userBox');
      box.put('access_token', token);
    } catch (e) {
      print('Error storing token: $e');
    }

    // Get storeId from SharedPreferences if not provided
    int finalStoreId = storeId ?? _getStoredStoreId() ?? 13; // fallback to 13

    connect(token, storeId: finalStoreId, driverId: driverId);
  }

  // Get stored store ID
  int? _getStoredStoreId() {
    try {
      var box = Hive.box('userBox');
      return box.get('store_id');
    } catch (e) {
      print('Error getting stored store_id: $e');
      return null;
    }
  }

  // Reconnect with stored token and provided IDs
  void reconnect({required int storeId, int? driverId}) {
    String? token = _getStoredToken();
    if (token != null) {
      disconnect();
      connect(token, storeId: storeId, driverId: driverId);
    } else {
      print('Cannot reconnect: No access token found');
    }
  }

  // Disconnect socket
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    _isConnected = false;
    connectionStatus.value = 'Disconnected';
    print('Reservation Socket disconnected and disposed');
  }

  // Manual refresh/reconnect
  void refresh({int? storeId, int? driverId}) {
    int finalStoreId = storeId ?? _getStoredStoreId() ?? 13;
    reconnect(storeId: finalStoreId, driverId: driverId);
  }

  // Update reservations list from API
  void updateReservationsList(List<GetUserReservationDetailsResponseModel> newList) {
    reservations.assignAll(newList);
  }

  // Send custom events (if needed)
  void emit(String event, Map<String, dynamic> data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
      print('📤 Emitted event: $event with data: $data');
    } else {
      print('Cannot emit event: Socket not connected');
    }
  }
}