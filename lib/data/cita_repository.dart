import 'package:sqflite/sqflite.dart';

import '../classes/cita_telemedicina.dart';
import '../classes/mensaje_teleconsulta.dart';
import '../classes/usuario_sistema.dart';
import '../common/catalogos_telemedicina.dart';
import '../services/push_notification_service.dart';
import 'local_database.dart';

class CitaRepository {
  static Future<UsuarioSistema?> autenticarORegistrarUsuario({
    required UsuarioSistema usuario,
    required bool esRegistro,
  }) async {
    final db = await LocalDatabase.instance.database;
    final limpio = usuario.cedula.trim();

    final existentes = await db.query(
      'usuarios',
      where: 'cedula = ?',
      whereArgs: [limpio],
    );

    if (existentes.isEmpty) {
      if (esRegistro) {
        await db.insert(
          'usuarios',
          usuario.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return usuario;
      } else {
        return null; 
      }
    }

    final encontrado = UsuarioSistema.fromMap(existentes.first);

    if (esRegistro) {
       final actualizado = UsuarioSistema(
        cedula: encontrado.cedula,
        nombre: usuario.nombre.isNotEmpty ? usuario.nombre : encontrado.nombre,
        ars: usuario.ars.isNotEmpty ? usuario.ars : encontrado.ars,
        nss: usuario.nss.isNotEmpty ? usuario.nss : encontrado.nss,
        email: usuario.email.isNotEmpty ? usuario.email : encontrado.email,
        telefono: usuario.telefono.isNotEmpty ? usuario.telefono : encontrado.telefono,
        passwordHash: encontrado.passwordHash, 
        rol: usuario.rol,
      );

      await db.update(
        'usuarios',
        actualizado.toMap(),
        where: 'cedula = ?',
        whereArgs: [limpio],
      );
      return actualizado;
    }

    return encontrado;
  }

  static Future<List<CitaTelemedicina>> obtenerTodasLasCitas(
      {String? cedulaFiltro}) async {
    final db = await LocalDatabase.instance.database;
    List<Map<String, Object?>> rows;

    if (cedulaFiltro != null) {
      rows = await db.query(
        'citas',
        where: 'cedula = ?',
        whereArgs: [cedulaFiltro],
        orderBy: 'fecha_hora DESC',
      );
    } else {
      rows = await db.query('citas', orderBy: 'fecha_hora DESC');
    }

    return rows.map(CitaTelemedicina.fromMap).toList();
  }

  static Future<void> guardarCita(CitaTelemedicina cita) async {
    final db = await LocalDatabase.instance.database;
    await db.insert(
      'citas',
      cita.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> eliminarCita(String id) async {
    final db = await LocalDatabase.instance.database;
    await db.delete('citas', where: 'id = ?', whereArgs: [id]);
    await db.delete(
      'mensajes_teleconsulta',
      where: 'cita_id = ?',
      whereArgs: [id],
    );
  }

  static Future<CitaTelemedicina> crearNuevaCita({
    required String nombrePaciente,
    required String cedula,
    required String ars,
    required String nss,
    required String especialidad,
    required String categoriaServicio,
    required String canalSolicitud,
    required String motivoConsulta,
    required String medicoAsignado,
    required DateTime fechaHora,
    bool dispararPush = true,
  }) async {
    final sufijo =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final salaRand =
        (100 + DateTime.now().millisecond % 899).toString().padLeft(3, '0');

    final tarifa =
        CatalogosTelemedicina.tarifasPorEspecialidad[especialidad] ?? 2500.0;
    final cobertura = tarifa * 0.80;
    final copago = tarifa - cobertura;

    final nueva = CitaTelemedicina(
      id: 'EXP-RD-2026-$sufijo',
      nombrePaciente: nombrePaciente,
      cedula: cedula,
      ars: ars,
      nss: nss,
      canalSolicitud: canalSolicitud,
      categoriaServicio: categoriaServicio,
      especialidad: especialidad,
      medicoAsignado: medicoAsignado,
      motivoConsulta: motivoConsulta,
      fechaHora: fechaHora,
      codigoSala: 'RD-SALA-$salaRand',
      citaAgendada: true,
      notificacionEnviada: true,
      montoTotalRD: tarifa,
      coberturaARSRD: cobertura,
      copagoPacienteRD: copago,
    );

    await guardarCita(nueva);

    await agregarMensajeSala(
      MensajeTeleconsulta(
        citaId: nueva.id,
        autor: 'Sistema Clínico PSS',
        rolAutor: 'Sistema',
        texto:
            'Expediente ${nueva.id} creado. Sala ${nueva.codigoSala} asignada.',
        fechaHora: DateTime.now(),
      ),
    );

    if (dispararPush) {
      await PushNotificationService.instance.enviarPushAgendamiento(
        expedienteId: nueva.id,
        nombrePaciente: nueva.nombrePaciente,
        especialidad: nueva.especialidad,
        medico: nueva.medicoAsignado,
        fechaHora: nueva.fechaHora,
        codigoSala: nueva.codigoSala,
      );
    }
    return nueva;
  }

  static Future<List<MensajeTeleconsulta>> obtenerMensajesSala(
      String citaId) async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query(
      'mensajes_teleconsulta',
      where: 'cita_id = ?',
      whereArgs: [citaId],
      orderBy: 'id ASC',
    );
    return rows.map(MensajeTeleconsulta.fromMap).toList();
  }

  static Future<void> agregarMensajeSala(MensajeTeleconsulta msg) async {
    final db = await LocalDatabase.instance.database;
    await db.insert('mensajes_teleconsulta', msg.toMap());
  }
}