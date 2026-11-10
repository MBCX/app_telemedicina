import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../classes/cita_telemedicina.dart';
import '../classes/mensaje_teleconsulta.dart';
import '../classes/rol_actor.dart';
import '../classes/usuario_sistema.dart';
import '../common/catalogos_telemedicina.dart';
import '../common/validador_dominicano.dart';

class LocalDatabase {
  LocalDatabase._internal();
  static final LocalDatabase instance = LocalDatabase._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    await init();
    return _db!;
  }

  Future<void> init() async {
    if (_db != null) return;

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      _db = await databaseFactory.openDatabase(
        'telesalud_rd_production.db',
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
        ),
      );
    } else {
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'telesalud_rd_production.db');
      _db = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE usuarios (
        cedula TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        ars TEXT NOT NULL,
        nss TEXT NOT NULL,
        email TEXT NOT NULL,
        telefono TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        rol TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE citas (
        id TEXT PRIMARY KEY,
        nombre_paciente TEXT NOT NULL,
        cedula TEXT NOT NULL,
        ars TEXT NOT NULL,
        nss TEXT NOT NULL,
        canal_solicitud TEXT NOT NULL,
        categoria_servicio TEXT NOT NULL,
        especialidad TEXT NOT NULL,
        medico_asignado TEXT NOT NULL,
        motivo_consulta TEXT NOT NULL,
        fecha_hora TEXT NOT NULL,
        plataforma_video TEXT NOT NULL,
        codigo_sala TEXT NOT NULL,
        solicitud_registrada INTEGER NOT NULL,
        recepcion_pss_completada INTEGER NOT NULL,
        seguro_validado INTEGER NOT NULL,
        numero_autorizacion_ars TEXT NOT NULL,
        cita_agendada INTEGER NOT NULL,
        notificacion_enviada INTEGER NOT NULL,
        consentimiento_firmado INTEGER NOT NULL,
        consulta_realizada INTEGER NOT NULL,
        prescripcion_emitida INTEGER NOT NULL,
        facturacion_cerrada INTEGER NOT NULL,
        seguimiento_registrado INTEGER NOT NULL,
        diagnostico_cie10 TEXT NOT NULL,
        notas_clinicas_soap TEXT NOT NULL,
        receta_medica TEXT NOT NULL,
        ordenes_laboratorio TEXT NOT NULL,
        ordenes_imagenes TEXT NOT NULL,
        referimiento TEXT NOT NULL,
        indicaciones_medicas TEXT NOT NULL,
        proxima_cita TEXT NOT NULL,
        presion_arterial TEXT NOT NULL,
        frecuencia_cardiaca INTEGER NOT NULL,
        saturacion_oxigeno INTEGER NOT NULL,
        temperatura_corporal REAL NOT NULL,
        monto_total_rd REAL NOT NULL,
        cobertura_ars_rd REAL NOT NULL,
        copago_paciente_rd REAL NOT NULL,
        ncf_factura TEXT NOT NULL,
        numero_reclamacion TEXT NOT NULL,
        calificacion_satisfaccion INTEGER NOT NULL,
        comentario_seguimiento TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE mensajes_teleconsulta (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cita_id TEXT NOT NULL,
        autor TEXT NOT NULL,
        rol_autor TEXT NOT NULL,
        texto TEXT NOT NULL,
        fecha_hora TEXT NOT NULL
      )
    ''');

    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final cedulaBase = ValidadorDominicano.generarCedulaValida('0011234567');
    final cedulaMedico = ValidadorDominicano.generarCedulaValida('0019876543');

    final usuarioInicial = UsuarioSistema(
      cedula: cedulaBase,
      nombre: 'María Fernanda Rodríguez',
      ars: CatalogosTelemedicina.arsRepublicaDominicana.first,
      nss: '10045892101',
      email: 'm.rodriguez@correo.do',
      telefono: '809-555-0192',
      passwordHash: 'TeleSalud2026*',
      rol: RolActor.paciente,
    );

    final medicoInicial = UsuarioSistema(
      cedula: cedulaMedico,
      nombre: 'Dr. Alejandro Méndez',
      ars: 'ARS Universal',
      nss: '90011223344',
      email: 'a.mendez@telesalud.do',
      telefono: '809-555-0800',
      passwordHash: 'Medico2026*',
      rol: RolActor.medico,
    );

    await db.insert('usuarios', usuarioInicial.toMap());
    await db.insert('usuarios', medicoInicial.toMap());

    final cita1 = CitaTelemedicina(
      id: 'EXP-RD-2026-101',
      nombrePaciente: usuarioInicial.nombre,
      cedula: usuarioInicial.cedula,
      ars: usuarioInicial.ars,
      nss: usuarioInicial.nss,
      canalSolicitud: 'Portal Web / App Institucional',
      categoriaServicio: 'Atención Clínica Especializada',
      especialidad: 'Cardiología de seguimiento',
      medicoAsignado: CatalogosTelemedicina.medicosDisponibles[1],
      motivoConsulta:
          'Control trimestral de hipertensión arterial y evaluación de monitoreo ambulatorio.',
      fechaHora: DateTime.now().add(const Duration(hours: 2)),
      codigoSala: 'RD-SALA-402',
      solicitudRegistrada: true,
      recepcionPSSCompletada: true,
      seguroValidado: true,
      numeroAutorizacionARS: 'AUT-SENASA-784120',
      citaAgendada: true,
      notificacionEnviada: true,
      consentimientoFirmado: true,
      montoTotalRD: 3200.0,
      coberturaARSRD: 2560.0,
      copagoPacienteRD: 640.0,
    );

    final cita2 = CitaTelemedicina(
      id: 'EXP-RD-2026-084',
      nombrePaciente: 'Carlos Eduardo Polanco',
      cedula: ValidadorDominicano.generarCedulaValida('0310456789'),
      ars: 'ARS Primera (Humano)',
      nss: '20094817264',
      canalSolicitud: 'WhatsApp Oficial PSS',
      categoriaServicio: 'Programas Asistenciales y Monitoreo',
      especialidad: 'Control de pacientes crónicos (HTA / Diabetes)',
      medicoAsignado: CatalogosTelemedicina.medicosDisponibles[0],
      motivoConsulta:
          'Revisión de hemoglobina glicosilada y ajuste de esquema hipoglucemiante.',
      fechaHora: DateTime.now().subtract(const Duration(days: 3)),
      codigoSala: 'RD-SALA-119',
      solicitudRegistrada: true,
      recepcionPSSCompletada: true,
      seguroValidado: true,
      numeroAutorizacionARS: 'AUT-HUMANO-553910',
      citaAgendada: true,
      notificacionEnviada: true,
      consentimientoFirmado: true,
      consultaRealizada: true,
      prescripcionEmitida: true,
      facturacionCerrada: true,
      seguimientoRegistrado: true,
      diagnosticoCIE10: 'E11.9 - Diabetes mellitus tipo 2 sin complicaciones',
      notasClinicasSOAP:
          'Paciente estable, glucemia en ayunas en 112 mg/dL, excelente tolerancia a metformina.',
      recetaMedica:
          'Metformina 850 mg VO cada 12 horas con las comidas por 90 días.',
      ordenesLaboratorio: [
        'HbA1c (Hemoglobina Glicosilada)',
        'Perfil Lipídico Completo (Colesterol, HDL, LDL, Triglicéridos)'
      ],
      ordenesImagenes: ['Sonografía Abdominal Completa'],
      referimiento: 'Nutrición y dietética',
      indicacionesMedicas:
          'Mantener actividad aeróbica 150 min/semana y dieta baja en carbohidratos refinados.',
      proximaCita: 'Control en 90 días',
      ncfFactura: 'B0100049281',
      numeroReclamacion: 'REC-SISALRIL-2026-44102',
      calificacionSatisfaccion: 5,
      comentarioSeguimiento:
          'Atención puntual y envío inmediato de órdenes firmadas.',
    );

    await db.insert('citas', cita1.toMap());
    await db.insert('citas', cita2.toMap());

    final msgInicial = MensajeTeleconsulta(
      citaId: cita1.id,
      autor: 'Sistema Clínico PSS',
      rolAutor: 'Sistema',
      texto:
          'Canal cifrado WebRTC P2P habilitado para expediente ${cita1.id}.',
      fechaHora: DateTime.now(),
    );
    await db.insert('mensajes_teleconsulta', msgInicial.toMap());
  }
}