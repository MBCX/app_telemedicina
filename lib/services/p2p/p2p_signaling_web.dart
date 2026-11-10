// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';
import 'dart:html' as html;

class WebSignalingHelper {
  static final Map<String, html.BroadcastChannel> _channels = {};
  static html.BroadcastChannel? _notifChannel;

  static Future<void> requestWebNotificationPermission() async {
    try {
      if (html.Notification.supported &&
          html.Notification.permission != 'granted') {
        await html.Notification.requestPermission();
      }
    } catch (_) {}
  }

  static void showAndBroadcastWebNotification({
    required String titulo,
    required String cuerpo,
    String? codigoSala,
  }) {
    try {
      if (html.Notification.supported &&
          html.Notification.permission == 'granted') {
        html.Notification(titulo, body: cuerpo);
      }
    } catch (_) {}
    try {
      _notifChannel ??= html.BroadcastChannel('telesalud_rd_push_channel');
      _notifChannel!.postMessage(jsonEncode({
        'titulo': titulo,
        'cuerpo': cuerpo,
        'codigoSala': codigoSala,
      }));
    } catch (_) {}
  }

  static void listenNotifications(
    void Function(Map<String, dynamic> data) onNotification,
  ) {
    try {
      _notifChannel ??= html.BroadcastChannel('telesalud_rd_push_channel');
      _notifChannel!.onMessage.listen((event) {
        if (event.data != null) {
          final decoded =
              jsonDecode(event.data.toString()) as Map<String, dynamic>;
          try {
            if (html.Notification.supported &&
                html.Notification.permission == 'granted') {
              html.Notification(
                decoded['titulo']?.toString() ?? 'TeleSalud RD',
                body: decoded['cuerpo']?.toString() ?? '',
              );
            }
          } catch (_) {}
          onNotification(decoded);
        }
      });
    } catch (_) {}
  }

  static void Function(Map<String, dynamic> msg) connectBroadcastChannel({
    required String channelName,
    required void Function(Map<String, dynamic> data) onMessage,
  }) {
    closeBroadcastChannel(channelName);
    final bc = html.BroadcastChannel('telesalud_rtc_$channelName');
    _channels[channelName] = bc;
    bc.onMessage.listen((event) {
      if (event.data != null) {
        try {
          final map = jsonDecode(event.data.toString()) as Map<String, dynamic>;
          onMessage(map);
        } catch (_) {}
      }
    });
    return (Map<String, dynamic> msg) {
      try {
        bc.postMessage(jsonEncode(msg));
      } catch (_) {}
    };
  }

  static void closeBroadcastChannel(String channelName) {
    final existing = _channels.remove(channelName);
    existing?.close();
  }
}