import 'package:flutter/material.dart';

import '../../../classes/cita_telemedicina.dart';
import '../../../classes/usuario_sistema.dart';
import '../../../common/catalogos_telemedicina.dart';
import '../../../common/validador_dominicano.dart';
import '../../../data/cita_repository.dart';

class NuevaCitaDialog extends StatefulWidget {
  final UsuarioSistema usuarioActual;
  final void Function(CitaTelemedicina) onCitaCreada;

  const NuevaCitaDialog({
    super.key,
    required this.usuarioActual,
    required this.onCitaCreada,
  });

  @override
  State<NuevaCitaDialog> createState() => _NuevaCitaDialogState();
}

class _NuevaCitaDialogState extends State<NuevaCitaDialog> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _cedulaCtrl;
  late TextEditingController _nssCtrl;
  late TextEditingController _motivoCtrl;

  late String _ars;
  String _especialidad = 'Medicina interna';
  String _medico = CatalogosTelemedicina.medicosDisponibles.first;
  String _canal = CatalogosTelemedicina.canalesDisponibles.first;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.usuarioActual.nombre);
    _cedulaCtrl = TextEditingController(text: widget.usuarioActual.cedula);
    _nssCtrl = TextEditingController(text: widget.usuarioActual.nss);
    _motivoCtrl = TextEditingController(
      text: 'Consulta de control clínico y evaluación de resultados.',
    );
    _ars = widget.usuarioActual.ars;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cedulaCtrl.dispose();
    _nssCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Apertura y Agendamiento de Nueva Cita'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Paciente Afiliado',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cedulaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Cédula RD',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _nssCtrl,
                      decoration: const InputDecoration(
                        labelText: 'NSS / Póliza',
                        prefixIcon: Icon(Icons.shield),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _ars,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'ARS Aseguradora',
                ),
                items: CatalogosTelemedicina.arsRepublicaDominicana
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _ars = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _especialidad,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Especialidad Requerida',
                ),
                items: CatalogosTelemedicina
                    .serviciosPorCategoria['Atención Clínica Especializada']!
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _especialidad = v);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _medico,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Especialista Asignado',
                ),
                items: CatalogosTelemedicina.medicosDisponibles
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _medico = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _canal,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Canal de Solicitud',
                ),
                items: CatalogosTelemedicina.canalesDisponibles
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _canal = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _motivoCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Motivo Clínico de Consulta',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () async {
            if (!ValidadorDominicano.validarCedulaRD(_cedulaCtrl.text)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'La Cédula ingresada no cumple con el Algoritmo Módulo 10 JCE.',
                  ),
                ),
              );
              return;
            }
            final creada = await CitaRepository.crearNuevaCita(
              nombrePaciente: _nombreCtrl.text.trim(),
              cedula: _cedulaCtrl.text.trim(),
              ars: _ars,
              nss: _nssCtrl.text.trim(),
              especialidad: _especialidad,
              categoriaServicio: 'Atención Clínica Especializada',
              canalSolicitud: _canal,
              motivoConsulta: _motivoCtrl.text.trim(),
              medicoAsignado: _medico,
              fechaHora: DateTime.now().add(const Duration(hours: 3)),
              dispararPush: true,
            );

            if (!mounted) return;
            Navigator.pop(context);
            widget.onCitaCreada(creada);
          },
          icon: const Icon(Icons.notifications_active),
          label: const Text('Agendar'),
        ),
      ],
    );
  }
}