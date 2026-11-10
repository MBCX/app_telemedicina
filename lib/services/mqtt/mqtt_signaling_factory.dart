import 'package:mqtt_client/mqtt_client.dart';
import 'mqtt_signaling_io.dart'
    if (dart.library.html) 'mqtt_signaling_web.dart';

MqttClient createPlatformMqttClient(String clientId) =>
    createMqttClientImpl(clientId);