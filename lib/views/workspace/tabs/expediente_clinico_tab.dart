import 'package:flutter/material.dart';
import '../../../classes/cita_telemedicina.dart';
import '../../../classes/usuario_sistema.dart';
import '../widgets/cabecera_expediente.dart';
import '../widgets/modulos_admision.dart';
import '../widgets/modulos_clinicos.dart';

class ExpedienteClinicoTab extends StatelessWidget {
  final CitaTelemedicina cita;
  final UsuarioSistema? usuarioActual;
  final Future<void> Function({String? mensajeConfirmacion}) onCambioGuardado;
  final bool isDesktop;
  final VoidCallback onIrASalaVideo;

  const ExpedienteClinicoTab({
    super.key,
    required this.cita,
    this.usuarioActual,
    required this.onCambioGuardado,
    required this.isDesktop,
    required this.onIrASalaVideo,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CabeceraExpediente(
                cita: cita,
                usuarioActual: usuarioActual,
                onCambioGuardado: onCambioGuardado,
              ),
              const SizedBox(height: 32),
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 16),
                child: Text(
                  'Fase 1: Admisión y Verificación',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005A9C),
                  ),
                ),
              ),
              ModulosAdmision(
                cita: cita,
                onCambioGuardado: onCambioGuardado,
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 16),
                child: Text(
                  'Fase 2: Atención Clínica y Cierre',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005A9C),
                  ),
                ),
              ),
              ModulosClinicos(
                cita: cita,
                onCambioGuardado: onCambioGuardado,
                onIrASalaVideo: onIrASalaVideo,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}