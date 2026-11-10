import 'package:flutter/material.dart';

import '../../../classes/cita_telemedicina.dart';
import '../../../data/cita_repository.dart';

class DirectorioExpedientesTab extends StatelessWidget {
  final List<CitaTelemedicina> citas;
  final CitaTelemedicina? citaActiva;
  final void Function(CitaTelemedicina) onCitaSeleccionada;
  final VoidCallback onNuevaCita;
  final Future<void> Function() onRecargarCitas;

  const DirectorioExpedientesTab({
    super.key,
    required this.citas,
    required this.citaActiva,
    required this.onCitaSeleccionada,
    required this.onNuevaCita,
    required this.onRecargarCitas,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Repositorio de Expedientes Clínicos (SQLite / IndexedDB)',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Selecciona cualquier expediente almacenado para gestionarlo, iniciar su teleconsulta o auditar su reclamación ARS.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: onNuevaCita,
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo Expediente'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...citas.map((c) {
                final esActiva = c.id == citaActiva?.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: esActiva
                          ? const Color(0xFF005A9C)
                          : Colors.grey.shade300,
                      width: esActiva ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: esActiva
                          ? const Color(0xFF005A9C)
                          : Colors.grey.shade200,
                      foregroundColor:
                          esActiva ? Colors.white : Colors.black87,
                      child: const Icon(Icons.folder_shared),
                    ),
                    title: Text(
                      '${c.nombrePaciente} - ${c.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Cédula: ${c.cedula} | ${c.ars} | Especialidad: ${c.especialidad}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estado: ${c.estadoGeneral} | Sala: ${c.codigoSala} | Avance: ${(c.porcentajeProgreso * 100).round()}%',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.tonal(
                          onPressed: () => onCitaSeleccionada(c),
                          child: Text(
                            esActiva ? 'Expediente Activo' : 'Abrir Expediente',
                          ),
                        ),
                        if (citas.length > 1)
                          IconButton(
                            tooltip: 'Eliminar expediente',
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: () async {
                              await CitaRepository.eliminarCita(c.id);
                              await onRecargarCitas();
                            },
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}