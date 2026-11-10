import 'package:flutter/material.dart';
import '../../../classes/cita_telemedicina.dart';
import '../../../classes/rol_actor.dart';
import '../../../classes/usuario_sistema.dart';
import '../../../services/push_notification_service.dart';

class CabeceraExpediente extends StatefulWidget {
  final CitaTelemedicina cita;
  final UsuarioSistema? usuarioActual;
  final Future<void> Function({String? mensajeConfirmacion}) onCambioGuardado;

  const CabeceraExpediente({
    super.key,
    required this.cita,
    this.usuarioActual,
    required this.onCambioGuardado,
  });

  @override
  State<CabeceraExpediente> createState() => _CabeceraExpedienteState();
}

class _CabeceraExpedienteState extends State<CabeceraExpediente> {
  @override
  Widget build(BuildContext context) {
    final cita = widget.cita;
    final usuario = widget.usuarioActual;
    final theme = Theme.of(context);

    final nombreMostrado = usuario?.nombre ?? cita.nombrePaciente;
    final cedulaMostrada = usuario?.cedula ?? cita.cedula;
    final arsMostrada = usuario?.ars ?? cita.ars;
    final nssMostrado = usuario?.nss ?? cita.nss;
    final medicoMostrado = (usuario != null && usuario.rol == RolActor.medico)
        ? usuario.nombre
        : cita.medicoAsignado;

    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor:
                      const Color(0xFF005A9C).withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF005A9C),
                    size: 42,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombreMostrado,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF005A9C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _buildInfoItem(Icons.badge, 'Cédula: $cedulaMostrada'),
                          _buildInfoItem(
                              Icons.health_and_safety, 'ARS: $arsMostrada'),
                          _buildInfoItem(Icons.shield, 'NSS: $nssMostrado'),
                          _buildInfoItem(Icons.folder_shared, 'Exp: ${cita.id}'),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text(
                        cita.estadoGeneral,
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam,
                              size: 18, color: Colors.black54),
                          const SizedBox(width: 6),
                          Text(
                            'Sala: ${cita.codigoSala}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progreso del Expediente',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${(cita.porcentajeProgreso * 100).toInt()}% Completado',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF005A9C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: cita.porcentajeProgreso,
                          backgroundColor: Colors.grey.shade300,
                          color: const Color(0xFF005A9C),
                          minHeight: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    backgroundColor: const Color(0xFF1E9E6A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    setState(() {
                      cita.solicitudRegistrada = true;
                      cita.recepcionPSSCompletada = true;
                      cita.seguroValidado = true;
                      if (cita.numeroAutorizacionARS.isEmpty) {
                        cita.numeroAutorizacionARS =
                            'AUT-ARS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                      }
                      cita.citaAgendada = true;
                      cita.notificacionEnviada = true;
                      cita.consentimientoFirmado = true;
                    });
                    await widget.onCambioGuardado();
                    await PushNotificationService.instance
                        .enviarPushAgendamiento(
                      expedienteId: cita.id,
                      nombrePaciente: nombreMostrado,
                      especialidad: cita.especialidad,
                      medico: medicoMostrado,
                      fechaHora: cita.fechaHora,
                      codigoSala: cita.codigoSala,
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 22),
                  label: const Text(
                    'Aprobar Admisión Rápida',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Especialidad: ${cita.especialidad}   |   Médico Asignado: $medicoMostrado',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}