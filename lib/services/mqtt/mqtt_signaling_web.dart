import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient createMqttClientImpl(String clientId) {
  final client = MqttBrowserClient.withPort(
    'wss://broker.emqx.io:8084/mqtt',
    clientId,
    8084,
  );
  client.keepAlivePeriod = 30;
  client.autoReconnect = true;
  client.resubscribeOnAutoReconnect = true;
  return client;
}