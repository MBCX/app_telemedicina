import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../classes/rol_actor.dart';
import '../../classes/usuario_sistema.dart';
import '../../common/catalogos_telemedicina.dart';
import '../../common/validador_dominicano.dart';
import '../../data/cita_repository.dart';
import '../workspace/workspace_screen.dart';

class AuthScreen extends StatefulWidget {
  final int initialTabIndex;

  const AuthScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKeyLogin = GlobalKey<FormState>();
  final _formKeySignUp = GlobalKey<FormState>();

  final TextEditingController _nombreCtrl = TextEditingController();
  late final TextEditingController _cedulaCtrl;
  final TextEditingController _nssCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();

  String _arsSeleccionada = CatalogosTelemedicina.arsRepublicaDominicana.first;
  RolActor _rolSeleccionado = RolActor.paciente;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _cedulaCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreCtrl.dispose();
    _cedulaCtrl.dispose();
    _nssCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _ingresarAlSistema({required bool esRegistro}) async {
    setState(() => _procesando = true);
    try {
      final usuario = UsuarioSistema(
        cedula: _cedulaCtrl.text.trim(),
        nombre: _nombreCtrl.text.trim(),
        ars: _arsSeleccionada,
        nss: _nssCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        passwordHash: '', // Contraseña ya no es requerida
        rol: _rolSeleccionado,
      );

      final autenticado = await CitaRepository.autenticarORegistrarUsuario(
        usuario: usuario,
        esRegistro: esRegistro,
      );

      if (!mounted) return;

      if (autenticado == null) {
        if (!esRegistro) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario no encontrado. Por favor, regístrate.'),
              backgroundColor: Colors.red,
            ),
          );
          _tabController.animateTo(1);
        }
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainTelemedicinaWorkspace(usuarioActual: autenticado),
        ),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cedulaEsValida = ValidadorDominicano.validarCedulaRD(
      _cedulaCtrl.text,
    );
    final nssEsValido = ValidadorDominicano.validarNSSoCarnetARS(_nssCtrl.text);

    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal Institucional TeleSalud RD'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amberAccent,
          indicatorWeight: 4,
          tabs: const [
            Tab(icon: Icon(Icons.login), text: 'Iniciar Sesión'),
            Tab(
              icon: Icon(Icons.person_add_alt_1),
              text: 'Registrarse (Nuevo Usuario)',
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 1040 : 620),
          child: Row(
            children: [
              if (isWide)
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      color: const Color(0xFF005A9C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.health_and_safety,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Sistema de Telemedicina Dominicana',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Validación algorítmica oficial JCE Módulo 10, RNC DGII Módulo 11 y padrón SISALRIL con base de datos local persistente.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14.5,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const SizedBox(height: 10),
                            _buildFeatureBadge(
                              Icons.videocam,
                              'Videoconsulta WebRTC/Agora con telemetría clínica',
                            ),
                            const SizedBox(height: 10),
                            _buildFeatureBadge(
                              Icons.receipt_long,
                              'Recetario digital CIE-10 y liquidación NCF / ARS',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(
                flex: 6,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoginTab(cedulaEsValida),
                    _buildSignUpTab(cedulaEsValida, nssEsValido),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.greenAccent, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginTab(bool cedulaEsValida) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeyLogin,
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Bienvenido de nuevo',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ingresa tu Cédula para acceder a tu perfil.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _cedulaCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Cédula de Identidad y Electoral',
                    hintText: '001-1234567-8',
                    prefixIcon: const Icon(Icons.credit_card),
                    suffixIcon: Icon(
                      cedulaEsValida ? Icons.verified : Icons.error_outline,
                      color: cedulaEsValida ? Colors.green : Colors.red,
                    ),
                  ),
                  validator: (val) {
                    if (val == null ||
                        !ValidadorDominicano.validarCedulaRD(val)) {
                      return 'Ingresa una Cédula válida (Módulo 10)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      if (kReleaseMode) {
                        return;
                      }
                      final random7 =
                          (1000000 + DateTime.now().millisecond * 812)
                              .toString()
                              .substring(0, 7);
                      final nueva = ValidadorDominicano.generarCedulaValida(
                        '001$random7',
                      );
                      setState(() => _cedulaCtrl.text = nueva);
                    },
                    icon: kReleaseMode
                        ? null
                        : const Icon(Icons.auto_fix_high, size: 16),
                    label: kReleaseMode
                        ? const Text("")
                        : const Text('Generar Cédula de Prueba'),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _procesando
                      ? null
                      : () {
                          if (_formKeyLogin.currentState!.validate()) {
                            _ingresarAlSistema(esRegistro: false);
                          }
                        },
                  icon: _procesando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Iniciar Sesión'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿No tienes una cuenta?'),
                    TextButton(
                      onPressed: () => _tabController.animateTo(1),
                      child: const Text('Regístrate aquí'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpTab(bool cedulaEsValida, bool nssEsValido) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeySignUp,
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Crear Nueva Cuenta',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Completa tus datos para afiliarte al sistema de TeleSalud.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<RolActor>(
                  initialValue: _rolSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Perfil Operativo',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: RolActor.values
                      .map(
                        (r) =>
                            DropdownMenuItem(value: r, child: Text(r.etiqueta)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _rolSeleccionado = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Campo obligatorio' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cedulaCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Cédula Dominicana',
                    prefixIcon: const Icon(Icons.badge),
                    suffixIcon: Icon(
                      cedulaEsValida ? Icons.check_circle : Icons.cancel,
                      color: cedulaEsValida ? Colors.green : Colors.red,
                    ),
                  ),
                  validator: (val) =>
                      (val == null || !ValidadorDominicano.validarCedulaRD(val))
                      ? 'Cédula inválida'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _arsSeleccionada,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'ARS (Aseguradora)',
                    prefixIcon: Icon(Icons.health_and_safety_outlined),
                  ),
                  items: CatalogosTelemedicina.arsRepublicaDominicana
                      .map(
                        (ars) => DropdownMenuItem(value: ars, child: Text(ars)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _arsSeleccionada = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nssCtrl,
                  onChanged: (_) => setState(() {}),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'NSS / No. de Carnet ARS',
                    prefixIcon: const Icon(Icons.shield_outlined),
                    suffixIcon: Icon(
                      nssEsValido ? Icons.verified : Icons.warning,
                      color: nssEsValido ? Colors.green : Colors.orange,
                    ),
                  ),
                  validator: (val) =>
                      (val == null ||
                          !ValidadorDominicano.validarNSSoCarnetARS(val))
                      ? 'Número de NSS inválido'
                      : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _telefonoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Celular',
                          hintText: '809 / 829 / 849',
                          prefixIcon: Icon(Icons.phone_android),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1E9E6A),
                  ),
                  onPressed: _procesando
                      ? null
                      : () {
                          if (_formKeySignUp.currentState!.validate()) {
                            _ingresarAlSistema(esRegistro: true);
                          }
                        },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Registrarme y Entrar'),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('¿Ya estás afiliado?'),
                    TextButton(
                      onPressed: () => _tabController.animateTo(0),
                      child: const Text('Inicia Sesión aquí'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
