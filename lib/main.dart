import 'package:flutter/material.dart';
import 'data/local_database.dart';
import 'services/push_notification_service.dart';
import 'styles/app_theme.dart';
import 'views/oobe/oobe_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalDatabase.instance.init();
  await PushNotificationService.instance.init();
  runApp(const TelemedicinaRDApp());
}

class TelemedicinaRDApp extends StatelessWidget {
  const TelemedicinaRDApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TeleSalud RD - Plataforma Clínica',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const OobeOnboardingScreen(),
    );
  }
}