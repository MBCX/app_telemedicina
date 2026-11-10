import 'package:flutter/material.dart';

import '../../../classes/cita_telemedicina.dart';
import '../../../common/catalogos_telemedicina.dart';

class CatalogoServiciosTab extends StatefulWidget {
  final CitaTelemedicina cita;
  final Future<void> Function({String? mensajeConfirmacion}) onCambioGuardado;

  const CatalogoServiciosTab({
    super.key,
    required this.cita,
    required this.onCambioGuardado,
  });

  @override
  State<CatalogoServiciosTab> createState() => _CatalogoServiciosTabState();
}

class _CatalogoServiciosTabState extends State<CatalogoServiciosTab> {
  @override
  Widget build(BuildContext context) {
    final cita = widget.cita;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cartera Institucional de Servicios de Telemedicina',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona cualquier prestación clínica, asistencial o derivada para asignarla al expediente activo (${cita.id}):',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ...CatalogosTelemedicina.serviciosPorCategoria.entries
                  .map((entry) {
                final categoria = entry.key;
                final servicios = entry.value;

                final esAsistencial =
                    categoria.contains('Programas Asistenciales');
                final colorCat = esAsistencial
                    ? const Color(0xFF1E9E6A)
                    : const Color(0xFF005A9C);

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colorCat,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14),
                          ),
                        ),
                        child: Text(
                          categoria,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: servicios.map((srv) {
                            final activo = cita.especialidad == srv;
                            return FilterChip(
                              selected: activo,
                              label: Text(srv),
                              onSelected: (_) {
                                final tarifa = CatalogosTelemedicina
                                        .tarifasPorEspecialidad[srv] ??
                                    2500.0;
                                setState(() {
                                  cita.categoriaServicio = categoria;
                                  cita.especialidad = srv;
                                  cita.montoTotalRD = tarifa;
                                  cita.coberturaARSRD = tarifa * 0.80;
                                  cita.copagoPacienteRD = tarifa * 0.20;
                                });
                                widget.onCambioGuardado(
                                  mensajeConfirmacion:
                                      'Servicio asignado al expediente: $srv (Tarifa: RD\$ ${tarifa.toStringAsFixed(0)})',
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
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