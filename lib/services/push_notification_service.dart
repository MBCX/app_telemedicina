// lib/services/push_notification_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'p2p/p2p_signaling_stub.dart'
    if (dart.library.html) 'p2p/p2p_signaling_web.dart';

class PushNotificationPayload {
  final String titulo;
  final String cuerpo;
  final String? codigoSala;
  final DateTime fechaHora;

  const PushNotificationPayload({
    required this.titulo,
    required this.cuerpo,
    this.codigoSala,
    required this.fechaHora,
  });
}

class PushNotificationService {
  PushNotificationService._internal();
  static final PushNotificationService instance =
      PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final StreamController<PushNotificationPayload> _inAppStream =
      StreamController<PushNotificationPayload>.broadcast();

  Stream<PushNotificationPayload> get onNotificationStream =>
      _inAppStream.stream;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      await WebSignalingHelper.requestWebNotificationPermission();
      WebSignalingHelper.listenNotifications((map) {
        final payload = PushNotificationPayload(
          titulo: map['titulo']?.toString() ?? 'Notificación TeleSalud RD',
          cuerpo: map['cuerpo']?.toString() ?? '',
          codigoSala: map['codigoSala']?.toString(),
          fechaHora: DateTime.now(),
        );
        _inAppStream.add(payload);
      });
      _initialized = true;
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      await Permission.notification.request();
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Abrir');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    try {
      await _localNotifications.initialize(initSettings);
    } catch (_) {}

    _initialized = true;
  }

  Future<void> enviarPushAgendamiento({
    required String expedienteId,
    required String nombrePaciente,
    required String especialidad,
    required String medico,
    required DateTime fechaHora,
    required String codigoSala,
  }) async {
    await init();

    final fechaStr =
        '${fechaHora.day.toString().padLeft(2, '0')}/${fechaHora.month.toString().padLeft(2, '0')}/${fechaHora.year} '
        '${fechaHora.hour.toString().padLeft(2, '0')}:${fechaHora.minute.toString().padLeft(2, '0')}';

    final titulo = 'Cita Agendada • $especialidad ($expedienteId)';
    final cuerpo =
        'Paciente: $nombrePaciente | Médico: $medico | Fecha: $fechaStr | Sala: $codigoSala';

    final payload = PushNotificationPayload(
      titulo: titulo,
      cuerpo: cuerpo,
      codigoSala: codigoSala,
      fechaHora: DateTime.now(),
    );

    _inAppStream.add(payload);

    if (kIsWeb) {
      WebSignalingHelper.showAndBroadcastWebNotification(
        titulo: titulo,
        cuerpo: cuerpo,
        codigoSala: codigoSala,
      );
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'telesalud_agendamientos_channel',
      'Agendamiento de Citas TeleSalud RD',
      channelDescription:
          'Notificaciones Push cuando se agendan o actualizan citas médicas',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Cita TeleSalud RD',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        titulo,
        cuerpo,
        details,
        payload: codigoSala,
      );
    } catch (_) {}
  }
}