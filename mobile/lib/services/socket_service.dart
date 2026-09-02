// ─────────────────────────────────────────────────────────────
// REALTIME — عميل Socket.IO (F2) بمطابقة سلوك الويب
// io('/?XTransformPort=3002') + join غرفة stay:{id}
// أحداث §1.5: chat:message · request:updated · notification:new · stay:updated
// ─────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config.dart';

class RealtimeEvent {
  const RealtimeEvent(this.name, this.payload);

  final String name;
  final dynamic payload;

  /// عنوان الإشعار من الحمولة إن وجد (كما في الويب)
  String get notificationTitle {
    final p = payload;
    if (p is Map<String, dynamic> && p['title'] is String) {
      return p['title'] as String;
    }
    return 'إشعار جديد';
  }
}

class RealtimeService {
  RealtimeService();

  io.Socket? _socket;
  StreamController<RealtimeEvent>? _controller;

  String? _joinedRoom;
  bool _disposed = false;

  /// بث الأحداث الواردة
  Stream<RealtimeEvent> get events {
    _controller ??= StreamController<RealtimeEvent>.broadcast();
    return _controller!.stream;
  }

  bool get connected => _socket?.connected ?? false;

  static const List<String> _listenEvents = [
    'chat:message',
    'request:new',
    'request:updated',
    'notification:new',
    'stay:updated',
  ];

  /// الانضمام لغرفة الإقامة — يعيد الاتصال عند تغير الغرفة
  void joinStayRoom(String stayId) {
    final room = 'stay:$stayId';
    if (_joinedRoom == room && _socket != null) return;
    _joinedRoom = room;
    _connect();
  }

  void _connect() {
    disconnect();
    if (_disposed || AppConfig.baseUrl.isEmpty) return;
    final socket = io.io(
      AppConfig.baseUrl,
      io.OptionBuilder()
          .setPath('/')
          .setQuery({'XTransformPort': AppConfig.realtimePort})
          .setTransports(['websocket', 'polling'])
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) {
      final room = _joinedRoom;
      if (room != null) {
        socket.emit('join', room);
      }
    });

    for (final ev in _listenEvents) {
      socket.on(ev, (payload) {
        _controller?.add(RealtimeEvent(ev, payload));
      });
    }
  }

  /// قطع الاتصال (عند الخروج/انتهاء الجلسة)
  void disconnect() {
    final s = _socket;
    if (s != null) {
      try {
        s.dispose();
      } catch (_) {}
    }
    _socket = null;
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _controller?.close();
    _controller = null;
  }
}
