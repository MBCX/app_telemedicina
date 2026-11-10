import 'dart:convert';

class CitaTelemedicina {
  String id;
  String nombrePaciente;
  String cedula;
  String ars;
  String nss;
  String canalSolicitud;
  String categoriaServicio;
  String especialidad;
  String medicoAsignado;
  String motivoConsulta;
  DateTime fechaHora;
  String plataformaVideo;
  String codigoSala;

  bool solicitudRegistrada;
  bool recepcionPSSCompletada;
  bool seguroValidado;
  String numeroAutorizacionARS;
  bool citaAgendada;
  bool notificacionEnviada;
  bool consentimientoFirmado;
  bool consultaRealizada;
  bool prescripcionEmitida;
  bool facturacionCerrada;
  bool seguimientoRegistrado;

  String diagnosticoCIE10;
  String notasClinicasSOAP;
  String recetaMedica;
  List<String> ordenesLaboratorio;
  List<String> ordenesImagenes;
  String referimiento;
  String indicacionesMedicas;
  String proximaCita;

  String presionArterial;
  int frecuenciaCardiaca;
  int saturacionOxigeno;
  double temperaturaCorporal;

  double montoTotalRD;
  double coberturaARSRD;
  double copagoPacienteRD;
  String ncfFactura;
  String numeroReclamacion;
  int calificacionSatisfaccion;
  String comentarioSeguimiento;

  CitaTelemedicina({
    required this.id,
    required this.nombrePaciente,
    required this.cedula,
    required this.ars,
    required this.nss,
    required this.canalSolicitud,
    required this.categoriaServicio,
    required this.especialidad,
    this.medicoAsignado = 'Dr. Alejandro Méndez (Exequátur 489-19)',
    required this.motivoConsulta,
    required this.fechaHora,
    this.plataformaVideo = 'Sala Integrada P2P (WebRTC)',
    required this.codigoSala,
    this.solicitudRegistrada = true,
    this.recepcionPSSCompletada = false,
    this.seguroValidado = false,
    this.numeroAutorizacionARS = '',
    this.citaAgendada = false,
    this.notificacionEnviada = false,
    this.consentimientoFirmado = false,
    this.consultaRealizada = false,
    this.prescripcionEmitida = false,
    this.facturacionCerrada = false,
    this.seguimientoRegistrado = false,
    this.diagnosticoCIE10 = 'I10 - Hipertensión esencial (primaria)',
    this.notasClinicasSOAP = '',
    this.recetaMedica = '',
    List<String>? ordenesLaboratorio,
    List<String>? ordenesImagenes,
    this.referimiento = '',
    this.indicacionesMedicas = '',
    this.proximaCita = '',
    this.presionArterial = '120/80',
    this.frecuenciaCardiaca = 74,
    this.saturacionOxigeno = 98,
    this.temperaturaCorporal = 36.6,
    this.montoTotalRD = 2500.0,
    this.coberturaARSRD = 2000.0,
    this.copagoPacienteRD = 500.0,
    this.ncfFactura = '',
    this.numeroReclamacion = '',
    this.calificacionSatisfaccion = 0,
    this.comentarioSeguimiento = '',
  })  : ordenesLaboratorio = ordenesLaboratorio ?? [],
        ordenesImagenes = ordenesImagenes ?? [];

  double get porcentajeProgreso {
    int completados = 0;
    if (solicitudRegistrada) completados++;
    if (recepcionPSSCompletada) completados++;
    if (seguroValidado) completados++;
    if (citaAgendada) completados++;
    if (notificacionEnviada) completados++;
    if (consentimientoFirmado) completados++;
    if (consultaRealizada) completados++;
    if (prescripcionEmitida) completados++;
    if (facturacionCerrada) completados++;
    if (seguimientoRegistrado) completados++;
    return completados / 10.0;
  }

  String get estadoGeneral {
    if (seguimientoRegistrado && facturacionCerrada) {
      return 'Expediente Cerrado y Auditado';
    }
    if (prescripcionEmitida) {
      return 'Pendiente Liquidación ARS';
    }
    if (consultaRealizada) {
      return 'En Emisión de Órdenes Médicas';
    }
    if (consentimientoFirmado && seguroValidado && citaAgendada) {
      return 'Habilitada para Teleconsulta';
    }
    if (seguroValidado) {
      return 'Cobertura Aprobada - En Admisión';
    }
    if (recepcionPSSCompletada) {
      return 'En Verificación de Póliza ARS';
    }
    return 'Solicitud Recibida en PSS';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre_paciente': nombrePaciente,
      'cedula': cedula,
      'ars': ars,
      'nss': nss,
      'canal_solicitud': canalSolicitud,
      'categoria_servicio': categoriaServicio,
      'especialidad': especialidad,
      'medico_asignado': medicoAsignado,
      'motivo_consulta': motivoConsulta,
      'fecha_hora': fechaHora.toIso8601String(),
      'plataforma_video': plataformaVideo,
      'codigo_sala': codigoSala,
      'solicitud_registrada': solicitudRegistrada ? 1 : 0,
      'recepcion_pss_completada': recepcionPSSCompletada ? 1 : 0,
      'seguro_validado': seguroValidado ? 1 : 0,
      'numero_autorizacion_ars': numeroAutorizacionARS,
      'cita_agendada': citaAgendada ? 1 : 0,
      'notificacion_enviada': notificacionEnviada ? 1 : 0,
      'consentimiento_firmado': consentimientoFirmado ? 1 : 0,
      'consulta_realizada': consultaRealizada ? 1 : 0,
      'prescripcion_emitida': prescripcionEmitida ? 1 : 0,
      'facturacion_cerrada': facturacionCerrada ? 1 : 0,
      'seguimiento_registrado': seguimientoRegistrado ? 1 : 0,
      'diagnostico_cie10': diagnosticoCIE10,
      'notas_clinicas_soap': notasClinicasSOAP,
      'receta_medica': recetaMedica,
      'ordenes_laboratorio': jsonEncode(ordenesLaboratorio),
      'ordenes_imagenes': jsonEncode(ordenesImagenes),
      'referimiento': referimiento,
      'indicaciones_medicas': indicacionesMedicas,
      'proxima_cita': proximaCita,
      'presion_arterial': presionArterial,
      'frecuencia_cardiaca': frecuenciaCardiaca,
      'saturacion_oxigeno': saturacionOxigeno,
      'temperatura_corporal': temperaturaCorporal,
      'monto_total_rd': montoTotalRD,
      'cobertura_ars_rd': coberturaARSRD,
      'copago_paciente_rd': copagoPacienteRD,
      'ncf_factura': ncfFactura,
      'numero_reclamacion': numeroReclamacion,
      'calificacion_satisfaccion': calificacionSatisfaccion,
      'comentario_seguimiento': comentarioSeguimiento,
    };
  }

  factory CitaTelemedicina.fromMap(Map<String, dynamic> map) {
    List<String> decodeList(dynamic raw) {
      if (raw == null || (raw as String).isEmpty) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    }

    return CitaTelemedicina(
      id: map['id'] as String,
      nombrePaciente: map['nombre_paciente'] as String,
      cedula: map['cedula'] as String,
      ars: map['ars'] as String,
      nss: map['nss'] as String,
      canalSolicitud: map['canal_solicitud'] as String,
      categoriaServicio: map['categoria_servicio'] as String,
      especialidad: map['especialidad'] as String,
      medicoAsignado: (map['medico_asignado'] as String?) ??
          'Dr. Alejandro Méndez (Exequátur 489-19)',
      motivoConsulta: map['motivo_consulta'] as String,
      fechaHora: DateTime.parse(map['fecha_hora'] as String),
      plataformaVideo: map['plataforma_video'] as String,
      codigoSala: map['codigo_sala'] as String,
      solicitudRegistrada: (map['solicitud_registrada'] as int) == 1,
      recepcionPSSCompletada: (map['recepcion_pss_completada'] as int) == 1,
      seguroValidado: (map['seguro_validado'] as int) == 1,
      numeroAutorizacionARS: map['numero_autorizacion_ars'] as String,
      citaAgendada: (map['cita_agendada'] as int) == 1,
      notificacionEnviada: (map['notificacion_enviada'] as int) == 1,
      consentimientoFirmado: (map['consentimiento_firmado'] as int) == 1,
      consultaRealizada: (map['consulta_realizada'] as int) == 1,
      prescripcionEmitida: (map['prescripcion_emitida'] as int) == 1,
      facturacionCerrada: (map['facturacion_cerrada'] as int) == 1,
      seguimientoRegistrado: (map['seguimiento_registrado'] as int) == 1,
      diagnosticoCIE10: (map['diagnostico_cie10'] as String?) ?? '',
      notasClinicasSOAP: (map['notas_clinicas_soap'] as String?) ?? '',
      recetaMedica: map['receta_medica'] as String,
      ordenesLaboratorio: decodeList(map['ordenes_laboratorio']),
      ordenesImagenes: decodeList(map['ordenes_imagenes']),
      referimiento: map['referimiento'] as String,
      indicacionesMedicas: map['indicaciones_medicas'] as String,
      proximaCita: map['proxima_cita'] as String,
      presionArterial: (map['presion_arterial'] as String?) ?? '120/80',
      frecuenciaCardiaca: (map['frecuencia_cardiaca'] as int?) ?? 74,
      saturacionOxigeno: (map['saturacion_oxigeno'] as int?) ?? 98,
      temperaturaCorporal:
          ((map['temperatura_corporal'] as num?) ?? 36.6).toDouble(),
      montoTotalRD: (map['monto_total_rd'] as num).toDouble(),
      coberturaARSRD: (map['cobertura_ars_rd'] as num).toDouble(),
      copagoPacienteRD: (map['copago_paciente_rd'] as num).toDouble(),
      ncfFactura: (map['ncf_factura'] as String?) ?? '',
      numeroReclamacion: map['numero_reclamacion'] as String,
      calificacionSatisfaccion: map['calificacion_satisfaccion'] as int,
      comentarioSeguimiento: map['comentario_seguimiento'] as String,
    );
  }
}