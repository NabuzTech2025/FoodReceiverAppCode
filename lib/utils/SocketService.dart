// socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void initSocket({
    required Function(dynamic) onNewOrder,
    required Function(dynamic) onOrderUpdated,
  }) {
    socket = IO.io(
      'http://62.171.181.21',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/ws-sio/socket.io')
          .enableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      print('✅ Connected to socket');
      socket.emit('join_store', {'store_id': 4});
    });

    socket.on('joined_store', (data) {
      print('✅ Joined room: ${data['room']}');
    });

    socket.on('new_order', (data) {
      print('🆕 New order: $data');
      onNewOrder(data);
    });

    socket.on('order_updated', (data) {
      print('🔄 Order updated: $data');
      onOrderUpdated(data);
    });

    socket.onDisconnect((_) {
      print('❌ Disconnected from socket');
    });
  }

  void dispose() {
    socket.disconnect();
    socket.dispose();
  }
}
