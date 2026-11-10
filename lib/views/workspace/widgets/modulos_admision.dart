import 'package:flutter/material.dart';

import '../../../classes/cita_telemedicina.dart';
import '../../../common/catalogos_telemedicina.dart';
import '../../../common/validador_dominicano.dart';
import '../../../components/modulo_clinico_card.dart';
import '../../../data/cita_repository.dart';
import '../../../services/push_notification_service.dart';

class ModulosAdmision extends StatefulWidget {
  final CitaTelemedicina cita;
  final Future<void> Function({String? mensajeConfirmacion}) onCambioGuardado;

  const ModulosAdmision({
    super.key,
    required this.cita,
    required this.onCambioGuardado,
  });

  @override
  State<ModulosAdmision> createState() => _ModulosAdmisionState();
}

class _ModulosAdmisionState extends State<ModulosAdmision> {
  @override
  Widget build(BuildContext context) {
    final cita = widget.cita;

    return Column(
      children: [
        ModuloClinicoCard(
          icono: Icons.contact_phone_outlined,
          titulo: 'Solicitud de Atención y Motivo Clínico',
          responsable: 'Paciente Afiliado / Canal de Entrada',
          estadoEtiqueta: cita.solicitudRegistrada ? 'Registrada' : 'Pendiente',
          verificado: cita.solicitudRegistrada,
          colorHeader: const Color(0xFF005A9C),
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Canal de recepción utilizado por el afiliado para solicitar la asistencia médica:',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CatalogosTelemedicina.canalesDisponibles.map((c) {
                  final seleccionado = cita.canalSolicitud == c;
                  return ChoiceChip(
                    label: Text(c),
                    selected: seleccionado,
                    onSelected: (_) {
                      setState(() => cita.canalSolicitud = c);
                      widget.onCambioGuardado();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: ValueKey('motivo_${cita.id}'),
                initialValue: cita.motivoConsulta,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Sintomatología o motivo de consulta reportado',
                  isDense: true,
                ),
                onChanged: (v) {
                  cita.motivoConsulta = v;
                  CitaRepository.guardarCita(cita);
                },
              ),
            ],
          ),
        ),
        ModuloClinicoCard(
          icono: Icons.fact_check_outlined,
          titulo: 'Recepción y Triaje en Prestadora de Salud (PSS)',
          responsable: 'Unidad de Admisión y Atención al Usuario',
          estadoEtiqueta:
              cita.recepcionPSSCompletada ? 'Admitido en PSS' : 'En Triaje',
          verificado: cita.recepcionPSSCompletada,
          colorHeader: const Color(0xFF1E9E6A),
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verificación de datos demográficos, asignación de facultativo especialista y registro de signos vitales basales:',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: CatalogosTelemedicina.medicosDisponibles
                        .contains(cita.medicoAsignado)
                    ? cita.medicoAsignado
                    : CatalogosTelemedicina.medicosDisponibles.first,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Médico Especialista Asignado',
                  prefixIcon: Icon(Icons.medical_information_outlined),
                ),
                items: CatalogosTelemedicina.medicosDisponibles
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => cita.medicoAsignado = val);
                    widget.onCambioGuardado();
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('pa_${cita.id}'),
                      initialValue: cita.presionArterial,
                      decoration: const InputDecoration(
                        labelText: 'PA (mmHg)',
                        isDense: true,
                      ),
                      onChanged: (v) {
                        cita.presionArterial = v;
                        CitaRepository.guardarCita(cita);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('fc_${cita.id}'),
                      initialValue: cita.frecuenciaCardiaca.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'FC (bpm)',
                        isDense: true,
                      ),
                      onChanged: (v) {
                        cita.frecuenciaCardiaca = int.tryParse(v) ?? 74;
                        CitaRepository.guardarCita(cita);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('spo2_${cita.id}'),
                      initialValue: cita.saturacionOxigeno.toString(),
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'SpO2 (%)',
                        isDense: true,
                      ),
                      onChanged: (v) {
                        cita.saturacionOxigeno = int.tryParse(v) ?? 98;
                        CitaRepository.guardarCita(cita);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  setState(() => cita.recepcionPSSCompletada = true);
                  widget.onCambioGuardado(
                    mensajeConfirmacion:
                        'Recepción y triaje en la PSS guardados en base de datos.',
                  );
                },
                icon: const Icon(Icons.assignment_turned_in),
                label: Text(
                  cita.recepcionPSSCompletada
                      ? 'Recepción en PSS Validada'
                      : 'Confirmar Admisión y Triaje en PSS',
                ),
              ),
            ],
          ),
        ),
        ModuloClinicoCard(
          icono: Icons.health_and_safety_outlined,
          titulo: 'Elegibilidad y Cobertura de Seguro (ARS / SISALRIL)',
          responsable: 'Auditoría de Seguros + Validador Padrón SISALRIL',
          estadoEtiqueta: cita.seguroValidado ? 'Autorizada' : 'Sin Autorizar',
          verificado: cita.seguroValidado,
          colorHeader: const Color(0xFF1E9E6A),
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comprobación de afiliación activa en ${cita.ars}, cobertura del Plan Básico de Salud (PDSS) y emisión de código de autorización.',
              ),
              const SizedBox(height: 10),
              if (cita.seguroValidado)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    'Póliza Activa | Cédula Módulo 10 Verificada | Autorización ARS: ${cita.numeroAutorizacionARS} | Cobertura 80% (RD\$ ${cita.coberturaARSRD.toStringAsFixed(2)}) / Copago: RD\$ ${cita.copagoPacienteRD.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: () {
                  final cedulaOk =
                      ValidadorDominicano.validarCedulaRD(cita.cedula);
                  final nssOk =
                      ValidadorDominicano.validarNSSoCarnetARS(cita.nss);

                  if (cedulaOk && nssOk) {
                    setState(() {
                      cita.seguroValidado = true;
                      cita.numeroAutorizacionARS =
                          'AUT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                    });
                    widget.onCambioGuardado(
                      mensajeConfirmacion:
                          'Cobertura ARS autorizada con número ${cita.numeroAutorizacionARS}.',
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Error de validación en Cédula o NSS del afiliado.',
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.verified_user),
                label: Text(
                  cita.seguroValidado
                      ? 'Autorización ARS Vigente (${cita.numeroAutorizacionARS})'
                      : 'Validar Cédula + NSS y Generar Autorización ARS',
                ),
              ),
            ],
          ),
        ),
        ModuloClinicoCard(
          icono: Icons.calendar_month_outlined,
          titulo: 'Programación de Agenda y Notificación Push al Afiliado',
          responsable: 'Coordinación de Consultas Externas',
          estadoEtiqueta: (cita.citaAgendada && cita.notificacionEnviada)
              ? 'Notificada Push'
              : 'Por Confirmar',
          verificado: cita.citaAgendada && cita.notificacionEnviada,
          colorHeader: const Color(0xFF005A9C),
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fecha y hora programadas: ${cita.fechaHora.day.toString().padLeft(2, '0')}/${cita.fechaHora.month.toString().padLeft(2, '0')}/${cita.fechaHora.year} a las ${cita.fechaHora.hour.toString().padLeft(2, '0')}:${cita.fechaHora.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Enlace institucional de sala: https://telesalud.do/sala/${cita.codigoSala}',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final fecha = await showDatePicker(
                        context: context,
                        initialDate: cita.fechaHora,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 120)),
                      );
                      if (fecha != null) {
                        setState(() {
                          cita.fechaHora = DateTime(
                            fecha.year,
                            fecha.month,
                            fecha.day,
                            cita.fechaHora.hour,
                            cita.fechaHora.minute,
                          );
                        });
                        await widget.onCambioGuardado();
                        await PushNotificationService.instance
                            .enviarPushAgendamiento(
                          expedienteId: cita.id,
                          nombrePaciente: cita.nombrePaciente,
                          especialidad: cita.especialidad,
                          medico: cita.medicoAsignado,
                          fechaHora: cita.fechaHora,
                          codigoSala: cita.codigoSala,
                        );
                      }
                    },
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Modificar Fecha'),
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      setState(() {
                        cita.citaAgendada = true;
                        cita.notificacionEnviada = true;
                      });
                      await widget.onCambioGuardado();
                      await PushNotificationService.instance
                          .enviarPushAgendamiento(
                        expedienteId: cita.id,
                        nombrePaciente: cita.nombrePaciente,
                        especialidad: cita.especialidad,
                        medico: cita.medicoAsignado,
                        fechaHora: cita.fechaHora,
                        codigoSala: cita.codigoSala,
                      );
                    },
                    icon: const Icon(Icons.notifications_active),
                    label: Text(
                      (cita.citaAgendada && cita.notificacionEnviada)
                          ? 'Reeconfirmar Agenda'
                          : 'Confirmar Agenda y Enviar Push',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ModuloClinicoCard(
          icono: Icons.gavel_outlined,
          titulo: 'Consentimiento Informado Digital (Ley 42-01)',
          responsable: 'Paciente Afiliado + Admisión Virtual',
          estadoEtiqueta:
              cita.consentimientoFirmado ? 'Firmado' : 'Pendiente Firma',
          verificado: cita.consentimientoFirmado,
          colorHeader: const Color(0xFF1E9E6A),
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Declaración de aceptación de asistencia médica a distancia conforme a la Ley General de Salud 42-01 y normativas de confidencialidad de datos clínicos.',
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: cita.consentimientoFirmado,
                title: const Text(
                  'El paciente acepta el consentimiento informado y valida su identidad mediante su Cédula de Identidad y Electoral.',
                ),
                onChanged: (val) {
                  setState(() => cita.consentimientoFirmado = val ?? false);
                  widget.onCambioGuardado();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}