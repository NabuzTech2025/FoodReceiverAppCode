import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;

  // Callback functions for different events
  Function(Map<String, dynamic>)? onSalesUpdate;
  Function(Map<String, dynamic>)? onNewOrder;
  Function(Map<String, dynamic>)? onOrderUpdate;
  Function()? onConnected;
  Function()? onDisconnected;

  bool get isConnected => _isConnected;

  void connect(String accessToken, {int storeId = 14}) {
    if (_socket != null && _isConnected) {
      print('Socket already connected');
      return;
    }

    try {
      _socket = IO.io('https://magskr.com', <String, dynamic>{
        'path': '/ws-sio/socket.io',
        'transports': ['websocket'],
        'auth': {
          'token': 'Bearer $accessToken',
        },
        'autoConnect': false,
      });

      _socket!.connect();

      // Connection successful
      _socket!.on('connect', (_) {
        print('✅ Connected to Socket.IO');
        _isConnected = true;

        // Join store room for order notifications
        _socket!.emit('join_store', {'store_id': storeId});

        // Join sales room for live sales updates
        _socket!.emit('join_store_sales', {'store_id': storeId});

        onConnected?.call();
      });

      // Joined store room confirmation
      _socket!.on('joined_store', (data) {
        print('✅ Joined room: ${data['room']}');
      });

      // Joined sales room confirmation
      _socket!.on('joined_sales_store', (data) {
        print('✅ Joined SALES room: ${data['room']}');
      });

      // Listen for sales updates (MAIN EVENT FOR YOUR USE CASE)
      _socket!.on('sales_update', (data) {
        print('💰 Sales update received:');
        print(data);
        if (data is Map<String, dynamic>) {
          onSalesUpdate?.call(data);
        }
      });

      // Listen for new orders
      _socket!.on('new_order', (data) {
        print('🆕 New order event:');
        print(data);
        if (data is Map<String, dynamic>) {
          onNewOrder?.call(data);
        }
      });

      // Listen for order updates
      _socket!.on('order_updated', (data) {
        print('🔁 Order update:');
        print(data);
        if (data is Map<String, dynamic>) {
          onOrderUpdate?.call(data);
        }
      });

      // Handle force logout
      _socket!.on('force_logout', (data) {
        print('🚫 Force logout received: $data');
        disconnect();
      });

      // Handle disconnection
      _socket!.on('disconnect', (_) {
        print('❌ Disconnected from Socket.IO');
        _isConnected = false;
        onDisconnected?.call();
      });

      // Handle connection errors
      _socket!.on('connect_error', (error) {
        print('❌ Connection error: $error');
        _isConnected = false;
      });

    } catch (e) {
      print('❌ Socket connection error: $e');
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      print('Socket disconnected and disposed');
    }
  }

  // Method to send custom events if needed
  void emit(String event, dynamic data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
    } else {
      print('Socket not connected. Cannot emit event: $event');
    }
  }
}