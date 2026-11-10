class WebSignalingHelper {
  static Future<void> requestWebNotificationPermission() async {}

  static void showAndBroadcastWebNotification({
    required String titulo,
    required String cuerpo,
    String? codigoSala,
  }) {}

  static void listenNotifications(
    void Function(Map<String, dynamic> data) onNotification,
  ) {}

  static void Function(Map<String, dynamic> msg) connectBroadcastChannel({
    required String channelName,
    required void Function(Map<String, dynamic> data) onMessage,
  }) {
    return (_) {};
  }

  static void closeBroadcastChannel(String channelName) {}
}