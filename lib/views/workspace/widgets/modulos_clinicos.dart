import 'package:flutter/material.dart';

import '../../../classes/cita_telemedicina.dart';
import '../../../common/catalogos_telemedicina.dart';
import '../../../components/modulo_clinico_card.dart';
import '../../../data/cita_repository.dart';

class ModulosClinicos extends StatefulWidget {
  final CitaTelemedicina cita;
  final Future<void> Function({String? mensajeConfirmacion}) onCambioGuardado;
  final VoidCallback onIrASalaVideo;

  const ModulosClinicos({
    super.key,
    required this.cita,
    required this.onCambioGuardado,
    required this.onIrASalaVideo,
  });

  @override
  State<ModulosClinicos> createState() => _ModulosClinicosState();
}

class _ModulosClinicosState extends State<ModulosClinicos> {
  @override
  Widget build(BuildContext context) {
    final cita = widget.cita;

    return Column(
      children: [
        ModuloClinicoCard(
          icono: Icons.videocam_outlined,
          titulo: 'Sesión de Teleconsulta Médica Sincrónica',
          responsable: 'Médico Especialista + Paciente + Soporte Técnico',
          estadoEtiqueta:
              cita.consultaRealizada ? 'Realizada' : 'Lista para Conectar',
          verificado: cita.consultaRealizada,
          colorHeader: const Color(0xFF1E9E6A),
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Evaluación médica por videollamada P2P con transmisión de signos vitales y bitácora clínica en tiempo real.',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CatalogosTelemedicina.plataformasVideo.map((p) {
                  return ChoiceChip(
                    label: Text(p),
                    selected: cita.plataformaVideo == p,
                    onSelected: (_) {
                      setState(() => cita.plataformaVideo = p);
                      widget.onCambioGuardado();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E9E6A),
                ),
                onPressed: widget.onIrASalaVideo,
                icon: const Icon(Icons.video_call),
                label: const Text('Abrir Sala de Teleconsulta en Vivo'),
              ),
            ],
          ),
        ),
        ModuloClinicoCard(
          icono: Icons.medication_outlined,
          titulo: 'Evolución Clínica SOAP, Recetario y Órdenes Médicas',
          responsable: 'Médico General o Especialista',
          estadoEtiqueta:
              cita.prescripcionEmitida ? 'Emitidas' : 'En Elaboración',
          verificado: cita.prescripcionEmitida,
          colorHeader: const Color(0xFF005A9C),
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                key: ValueKey('cie10_${cita.id}'),
                initialValue: cita.diagnosticoCIE10,
                decoration: const InputDecoration(
                  labelText: 'Diagnóstico Clínico Codificado (CIE-10)',
                  prefixIcon: Icon(Icons.medical_information),
                  isDense: true,
                ),
                onChanged: (v) {
                  cita.diagnosticoCIE10 = v;
                  CitaRepository.guardarCita(cita);
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: ValueKey('receta_${cita.id}'),
                initialValue: cita.recetaMedica,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Prescripción Farmacológica (Posología y Duración)',
                  hintText:
                      'Ej. Losartán Potásico 50 mg 1 tab c/24h por 30 días...',
                  isDense: true,
                ),
                onChanged: (v) {
                  cita.recetaMedica = v;
                  CitaRepository.guardarCita(cita);
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'Órdenes de Laboratorio Clínico:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: CatalogosTelemedicina.catalogoLaboratorios.map((lab) {
                  final incluido = cita.ordenesLaboratorio.contains(lab);
                  return FilterChip(
                    label: Text(lab, style: const TextStyle(fontSize: 12)),
                    selected: incluido,
                    onSelected: (sel) {
                      setState(() {
                        if (sel) {
                          cita.ordenesLaboratorio.add(lab);
                        } else {
                          cita.ordenesLaboratorio.remove(lab);
                        }
                      });
                      widget.onCambioGuardado();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              const Text(
                'Órdenes de Imágenes Diagnósticas:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: CatalogosTelemedicina.catalogoImagenes.map((img) {
                  final incluido = cita.ordenesImagenes.contains(img);
                  return FilterChip(
                    label: Text(img, style: const TextStyle(fontSize: 12)),
                    selected: incluido,
                    onSelected: (sel) {
                      setState(() {
                        if (sel) {
                          cita.ordenesImagenes.add(img);
                        } else {
                          cita.ordenesImagenes.remove(img);
                        }
                      });
                      widget.onCambioGuardado();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('ref_${cita.id}'),
                      initialValue: cita.referimiento,
                      decoration: const InputDecoration(
                        labelText: 'Referimiento Médico',
                        isDense: true,
                      ),
                      onChanged: (v) {
                        cita.referimiento = v;
                        CitaRepository.guardarCita(cita);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: ValueKey('prox_${cita.id}'),
                      initialValue: cita.proximaCita,
                      decoration: const InputDecoration(
                        labelText: 'Próximo Control',
                        isDense: true,
                      ),
                      onChanged: (v) {
                        cita.proximaCita = v;
                        CitaRepository.guardarCita(cita);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                key: ValueKey('ind_${cita.id}'),
                initialValue: cita.indicacionesMedicas,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Indicaciones No Farmacológicas y Plan Educativo',
                  isDense: true,
                ),
                onChanged: (v) {
                  cita.indicacionesMedicas = v;
                  CitaRepository.guardarCita(cita);
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    if (cita.recetaMedica.trim().isEmpty) {
                      cita.recetaMedica =
                          'Losartán Potásico 50 mg VO c/24h por 30 días + Amlodipina 5 mg VO nocturna.';
                    }
                    if (cita.ordenesLaboratorio.isEmpty) {
                      cita.ordenesLaboratorio = [
                        'Hemograma Completo Automatizado',
                        'Perfil Lipídico Completo (Colesterol, HDL, LDL, Triglicéridos)',
                        'Creatinina Sérica y Filtrado Glomerular',
                      ];
                    }
                    if (cita.ordenesImagenes.isEmpty) {
                      cita.ordenesImagenes = [
                        'Ecocardiograma Doppler Transtorácico'
                      ];
                    }
                    if (cita.referimiento.trim().isEmpty) {
                      cita.referimiento = 'Nutrición y dietética clínica';
                    }
                    if (cita.indicacionesMedicas.trim().isEmpty) {
                      cita.indicacionesMedicas =
                          'Dieta hiposódica estricta, caminata 30 min diarios y registro de PA matutina.';
                    }
                    if (cita.proximaCita.trim().isEmpty) {
                      cita.proximaCita = 'En 30 días (Consulta de seguimiento)';
                    }
                    cita.prescripcionEmitida = true;
                  });
                  widget.onCambioGuardado(
                    mensajeConfirmacion:
                        'Recetario, órdenes diagnósticas y referimiento firmados digitalmente.',
                  );
                },
                icon: const Icon(Icons.fact_check),
                label: Text(
                  cita.prescripcionEmitida
                      ? 'Actualizar y Firmar Prescripción Electrónica'
                      : 'Firmar y Emitir Receta, Órdenes y Referimiento',
                ),
              ),
            ],
          ),
        ),
        ModuloClinicoCard(
          icono: Icons.receipt_long_outlined,
          titulo: 'Facturación NCF, Reclamación ARS y Auditoría Médica',
          responsable: 'Departamento de Facturación y Auditoría PSS',
          estadoEtiqueta:
              cita.facturacionCerrada ? 'Liquidada' : 'En Liquidación',
          verificado: cita.facturacionCerrada,
          colorHeader: const Color(0xFF005A9C),
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Liquidación financiera ante ${cita.ars} con Comprobante Fiscal (NCF) y número de reclamación SISALRIL.',
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tarifa Institucional: RD\$ ${cita.montoTotalRD.toStringAsFixed(2)} | Cobertura ARS (80%): RD\$ ${cita.coberturaARSRD.toStringAsFixed(2)} | Copago Afiliado: RD\$ ${cita.copagoPacienteRD.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (cita.facturacionCerrada) ...[
                      const SizedBox(height: 4),
                      Text(
                        'NCF Emitido: ${cita.ncfFactura} | Reclamación: ${cita.numeroReclamacion}',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  final sufijo = DateTime.now()
                      .millisecondsSinceEpoch
                      .toString()
                      .substring(6);
                  setState(() {
                    cita.ncfFactura = 'B0100$sufijo';
                    cita.numeroReclamacion = 'REC-SISALRIL-2026-$sufijo';
                    cita.facturacionCerrada = true;
                  });
                  widget.onCambioGuardado(
                    mensajeConfirmacion:
                        'Factura ${cita.ncfFactura} y reclamación ${cita.numeroReclamacion} cerradas en SQLite.',
                  );
                },
                icon: const Icon(Icons.request_quote),
                label: Text(
                  cita.facturacionCerrada
                      ? 'Reclamación ${cita.numeroReclamacion} Auditada'
                      : 'Generar Comprobante NCF y Cerrar Reclamación ARS',
                ),
              ),
            ],
          ),
        ),
        ModuloClinicoCard(
          icono: Icons.thumbs_up_down_outlined,
          titulo: 'Seguimiento Postconsulta y Satisfacción del Afiliado',
          responsable: 'Atención al Usuario + Monitoreo Clínico',
          estadoEtiqueta:
              cita.seguimientoRegistrado ? 'Completado' : 'Pendiente Encuesta',
          verificado: cita.seguimientoRegistrado,
          colorHeader: const Color(0xFF1E9E6A),
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Evaluación de calidad asistencial percibida por el paciente y confirmación de adherencia al tratamiento prescrito:',
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  final estrella = index + 1;
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        cita.calificacionSatisfaccion = estrella;
                        cita.seguimientoRegistrado = true;
                      });
                      widget.onCambioGuardado(
                        mensajeConfirmacion:
                            'Evaluación de satisfacción ($estrella/5) almacenada.',
                      );
                    },
                    icon: Icon(
                      estrella <= cita.calificacionSatisfaccion
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber[700],
                      size: 32,
                    ),
                  );
                }),
              ),
              TextFormField(
                key: ValueKey('seg_${cita.id}'),
                initialValue: cita.comentarioSeguimiento,
                decoration: const InputDecoration(
                  labelText: 'Observaciones de seguimiento postconsulta',
                  isDense: true,
                ),
                onChanged: (v) {
                  cita.comentarioSeguimiento = v;
                  CitaRepository.guardarCita(cita);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}