import 'dart:async';
import 'package:flutter/material.dart';
import '../../classes/cita_telemedicina.dart';
import '../../classes/rol_actor.dart';
import '../../classes/usuario_sistema.dart';
import '../../common/catalogos_telemedicina.dart';
import '../../data/cita_repository.dart';
import '../../services/push_notification_service.dart';
import '../auth/auth_screen.dart';
import '../video/video_call_screen.dart';
import 'tabs/catalogo_servicios_tab.dart';
import 'tabs/directorio_expedientes_tab.dart';
import 'tabs/expediente_clinico_tab.dart';
import 'tabs/validador_dominicano_tab.dart';
import 'widgets/nueva_cita_dialogue.dart';

class MainTelemedicinaWorkspace extends StatefulWidget {
  final UsuarioSistema usuarioActual;

  const MainTelemedicinaWorkspace({
    super.key,
    required this.usuarioActual,
  });

  @override
  State<MainTelemedicinaWorkspace> createState() =>
      _MainTelemedicinaWorkspaceState();
}

class _MainTelemedicinaWorkspaceState extends State<MainTelemedicinaWorkspace> {
  int _selectedIndex = 0;
  List<CitaTelemedicina> _listaCitas = [];
  CitaTelemedicina? _citaActiva;
  bool _cargando = true;
  StreamSubscription<PushNotificationPayload>? _pushSub;
  final List<PushNotificationPayload> _historialNotificaciones = [];

  @override
  void initState() {
    super.initState();
    _cargarDatosDesdeSQLite();

    _pushSub =
        PushNotificationService.instance.onNotificationStream.listen((payload) {
      if (!mounted) return;
      setState(() {
        _historialNotificaciones.insert(0, payload);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF005A9C),
          duration: const Duration(seconds: 5),
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.amberAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payload.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      payload.cuerpo,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          action: payload.codigoSala != null
              ? SnackBarAction(
                  label: 'IR A SALA',
                  textColor: Colors.amberAccent,
                  onPressed: () {
                    setState(() => _selectedIndex = 3);
                  },
                )
              : null,
        ),
      );
    });
  }

  @override
  void dispose() {
    _pushSub?.cancel();
    super.dispose();
  }

  Future<void> _cargarDatosDesdeSQLite() async {
    setState(() => _cargando = true);

    var citas = await CitaRepository.obtenerTodasLasCitas(
      cedulaFiltro: widget.usuarioActual.cedula,
    );

    if (citas.isEmpty) {
      final esMedico = widget.usuarioActual.rol == RolActor.medico;
      final inicial = await CitaRepository.crearNuevaCita(
        nombrePaciente: widget.usuarioActual.nombre,
        cedula: widget.usuarioActual.cedula,
        ars: widget.usuarioActual.ars,
        nss: widget.usuarioActual.nss,
        especialidad: 'Consulta médica general',
        categoriaServicio: 'Atención Clínica Especializada',
        canalSolicitud: 'Portal Web / App Institucional',
        motivoConsulta:
            'Evaluación clínica preventiva y control de presión arterial.',
        medicoAsignado: esMedico
            ? widget.usuarioActual.nombre
            : CatalogosTelemedicina.medicosDisponibles.first,
        fechaHora: DateTime.now().add(const Duration(hours: 2)),
        dispararPush: false,
      );
      citas = [inicial];
    }

    if (widget.usuarioActual.rol != RolActor.paciente) {
      final todas = await CitaRepository.obtenerTodasLasCitas();
      for (final c in todas) {
        if (!citas.any((existente) => existente.id == c.id)) {
          citas.add(c);
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _listaCitas = citas;
      _citaActiva = citas.firstWhere(
        (c) => c.id == _citaActiva?.id,
        orElse: () => citas.first,
      );
      _cargando = false;
    });
  }

  Future<void> _guardarCambiosCitaActiva({String? mensajeConfirmacion}) async {
    final cita = _citaActiva;
    if (cita == null) return;
    await CitaRepository.guardarCita(cita);
    final actualizadas = widget.usuarioActual.rol == RolActor.paciente
        ? await CitaRepository.obtenerTodasLasCitas(
            cedulaFiltro: widget.usuarioActual.cedula)
        : await CitaRepository.obtenerTodasLasCitas();
    if (!mounted) return;
    setState(() {
      _listaCitas = actualizadas;
    });
    if (mensajeConfirmacion != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeConfirmacion),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _mostrarBandejaPush() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Color(0xFF005A9C)),
            SizedBox(width: 8),
            Text('Centro de Notificaciones'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: _historialNotificaciones.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No se han emitido notificaciones en esta sesión. Agenda una nueva cita o confirma una agenda para recibir alertas.',
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _historialNotificaciones.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, idx) {
                    final item = _historialNotificaciones[idx];
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF005A9C),
                        child: Icon(Icons.event_available, color: Colors.white),
                      ),
                      title: Text(
                        item.titulo,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(item.cuerpo),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoNuevaCita() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => NuevaCitaDialog(
        usuarioActual: widget.usuarioActual,
        onCitaCreada: (nuevaCita) async {
          await _cargarDatosDesdeSQLite();
          setState(() => _citaActiva = nuevaCita);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando || _citaActiva == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 960;

    final paginas = [
      ExpedienteClinicoTab(
        cita: _citaActiva!,
        usuarioActual: widget.usuarioActual,
        onCambioGuardado: _guardarCambiosCitaActiva,
        isDesktop: isDesktop,
        onIrASalaVideo: () => setState(() => _selectedIndex = 3),
      ),
      DirectorioExpedientesTab(
        citas: _listaCitas,
        citaActiva: _citaActiva,
        onCitaSeleccionada: (c) {
          setState(() {
            _citaActiva = c;
            _selectedIndex = 0;
          });
        },
        onNuevaCita: _mostrarDialogoNuevaCita,
        onRecargarCitas: _cargarDatosDesdeSQLite,
      ),
      CatalogoServiciosTab(
        cita: _citaActiva!,
        onCambioGuardado: _guardarCambiosCitaActiva,
      ),
      VideoCallTwoUsersScreen(
        cita: _citaActiva!,
        rolActual: widget.usuarioActual.rol,
        onConsultaCompletada: () {
          setState(() {
            _citaActiva!.consultaRealizada = true;
          });
          _guardarCambiosCitaActiva();
        },
      ),
      ValidadorDominicanoTab(
        usuarioActual: widget.usuarioActual,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.local_hospital_outlined, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TeleSalud RD - ${widget.usuarioActual.nombre}',
                    style: const TextStyle(
                        fontSize: 16.5, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rol activo: ${widget.usuarioActual.rol.etiqueta} | Expediente ${_citaActiva!.id} (${_citaActiva!.estadoGeneral})',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Notificaciones Push de Agendamiento',
            onPressed: _mostrarBandejaPush,
            icon: Badge(
              isLabelVisible: _historialNotificaciones.isNotEmpty,
              label: Text('${_historialNotificaciones.length}'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          const SizedBox(width: 4),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              foregroundColor: Colors.white,
            ),
            onPressed: _mostrarDialogoNuevaCita,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Nueva Consulta'),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
          ),
        ],
      ),
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  extended: MediaQuery.of(context).size.width >= 1240,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (idx) =>
                      setState(() => _selectedIndex = idx),
                  backgroundColor: Colors.white,
                  indicatorColor:
                      const Color(0xFF005A9C).withValues(alpha: 0.14),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.assignment_outlined),
                      selectedIcon:
                          Icon(Icons.assignment, color: Color(0xFF005A9C)),
                      label: Text('Expediente Activo'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.folder_shared_outlined),
                      selectedIcon:
                          Icon(Icons.folder_shared, color: Color(0xFF005A9C)),
                      label: Text('Citas y Base SQL'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.medical_services_outlined),
                      selectedIcon: Icon(Icons.medical_services,
                          color: Color(0xFF005A9C)),
                      label: Text('Cartera Clínica'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.videocam_outlined),
                      selectedIcon:
                          Icon(Icons.videocam, color: Color(0xFF005A9C)),
                      label: Text('Sala Teleconsulta'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.verified_user_outlined),
                      selectedIcon:
                          Icon(Icons.verified_user, color: Color(0xFF005A9C)),
                      label: Text('Auditoría JCE/DGII'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: paginas[_selectedIndex]),
              ],
            )
          : paginas[_selectedIndex],
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (idx) =>
                  setState(() => _selectedIndex = idx),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.assignment_outlined),
                  selectedIcon: Icon(Icons.assignment),
                  label: 'Expediente',
                ),
                NavigationDestination(
                  icon: Icon(Icons.folder_shared_outlined),
                  selectedIcon: Icon(Icons.folder_shared),
                  label: 'Base SQL',
                ),
                NavigationDestination(
                  icon: Icon(Icons.medical_services_outlined),
                  selectedIcon: Icon(Icons.medical_services),
                  label: 'Servicios',
                ),
                NavigationDestination(
                  icon: Icon(Icons.videocam_outlined),
                  selectedIcon: Icon(Icons.videocam),
                  label: 'Videollamada',
                ),
                NavigationDestination(
                  icon: Icon(Icons.verified_user_outlined),
                  selectedIcon: Icon(Icons.verified_user),
                  label: 'Auditoría RD',
                ),
              ],
            ),
    );
  }
}