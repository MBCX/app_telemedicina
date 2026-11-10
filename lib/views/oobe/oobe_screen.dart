import 'package:flutter/material.dart';
import '../auth/auth_screen.dart';

class OobeOnboardingScreen extends StatefulWidget {
  const OobeOnboardingScreen({super.key});

  @override
  State<OobeOnboardingScreen> createState() => _OobeOnboardingScreenState();
}

class _OobeOnboardingScreenState extends State<OobeOnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List _slides = [
    {
      'titulo': 'Red Nacional de Telemedicina',
      'subtitulo':
          'Plataforma Clínica y Administrativa para República Dominicana',
      'descripcion':
          'Integramos pacientes afiliados, Prestadoras de Servicios de Salud (PSS), especialistas acreditados y Administradoras de Riesgos de Salud (ARS) bajo estándares de trazabilidad clínica.',
      'icono': Icons.monitor_heart_outlined,
      'color': const Color(0xFF005A9C),
      'items': [
        'Atención omnicanal por Portal Web, Móvil, WhatsApp y Videoconferencia P2P',
        'Historia clínica electrónica con almacenamiento persistente SQLite / IndexedDB',
        'Integración normativa con el Sistema Dominicano de Seguridad Social (SDSS)',
      ],
    },
    {
      'titulo': 'Cartera Clínica, Asistencial y Derivada',
      'subtitulo': 'Gestión médica integral desde la admisión hasta el alta',
      'descripcion':
          'Cobertura completa de especialidades médicas, programas de seguimiento para condiciones crónicas y emisión electrónica de prescripciones y estudios.',
      'icono': Icons.medical_services_outlined,
      'color': const Color(0xFF1E9E6A),
      'items': [
        'Especialidades: Medicina Interna, Cardiología, Pediatría, Ginecología, Psicología y Nutrición',
        'Monitoreo continuo: Control de hipertensión, diabetes, postoperatorio y educación sanitaria',
        'Prescripción digital: Recetario electrónico, órdenes de laboratorio, imágenes y referimientos',
      ],
    },
    {
      'titulo': 'Validación JCE, SISALRIL y Teleconsulta',
      'subtitulo': 'Verificación documental en línea y sala de video en vivo',
      'descripcion':
          'Validamos la Cédula de Identidad y Electoral (Módulo 10), el RNC institucional (Módulo 11 DGII) y la póliza ARS antes de establecer la sesión de telemedicina.',
      'icono': Icons.verified_user_outlined,
      'color': const Color(0xFF0D7A5F),
      'items': [
        'Verificación instantánea de Cédula Dominicana (JCE) y NSS (SISALRIL)',
        'Firma digital de consentimiento informado conforme a la Ley General de Salud 42-01',
        'Sala de videoconferencia sincronizada para médico y paciente con telemetría de signos vitales',
      ],
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _irAAuth({int initialTabIndex = 0}) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AuthScreen(initialTabIndex: initialTabIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF005A9C)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.local_hospital,
                              color: Color(0xFF005A9C),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'TeleSalud RD',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF005A9C),
                                ),
                          ),
                        ],
                      ),
                      if (!isLastPage)
                        TextButton.icon(
                          onPressed: () => _irAAuth(initialTabIndex: 0),
                          icon: const Icon(Icons.skip_next, size: 18),
                          label: const Text('Omitir Introducción'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      final color = slide['color'] as Color;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                slide['icono'] as IconData,
                                size: 78,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              slide['titulo'] as String,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              slide['subtitulo'] as String,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 680),
                              child: Text(
                                slide['descripcion'] as String,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Colors.grey[700],
                                    ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 680),
                              child: Card(
                                elevation: 0,
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: (slide['items'] as List<String>)
                                        .map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  size: 20,
                                                  color: color,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    item,
                                                    style: const TextStyle(
                                                      fontSize: 14.5,
                                                      height: 1.35,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          _slides.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.only(right: 6),
                            height: 8,
                            width: _currentPage == index ? 28 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? const Color(0xFF005A9C)
                                  : Colors.grey[350],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      if (isLastPage)
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () => _irAAuth(initialTabIndex: 1),
                              child: const Text('Registrarme'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: () => _irAAuth(initialTabIndex: 0),
                              icon: const Icon(Icons.login),
                              label: const Text('Iniciar Sesión'),
                            ),
                          ],
                        )
                      else
                        FilledButton.icon(
                          onPressed: () {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Siguiente'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}