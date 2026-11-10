import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttClient createMqttClientImpl(String clientId) {
  final client = MqttServerClient.withPort(
    'broker.emqx.io',
    clientId,
    8084,
  );
  client.useWebSocket = true;
  client.secure = true;
  client.keepAlivePeriod = 30;
  client.autoReconnect = true;
  client.resubscribeOnAutoReconnect = true;
  return client;
}