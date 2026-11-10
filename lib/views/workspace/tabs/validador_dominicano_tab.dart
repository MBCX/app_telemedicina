import 'package:flutter/material.dart';

import '../../../classes/usuario_sistema.dart';
import '../../../common/validador_dominicano.dart';

class ValidadorDominicanoTab extends StatefulWidget {
  final UsuarioSistema usuarioActual;

  const ValidadorDominicanoTab({
    super.key,
    required this.usuarioActual,
  });

  @override
  State<ValidadorDominicanoTab> createState() => _ValidadorDominicanoTabState();
}

class _ValidadorDominicanoTabState extends State<ValidadorDominicanoTab> {
  late final TextEditingController _cedulaTestCtrl;
  final TextEditingController _rncTestCtrl =
      TextEditingController(text: '101019921');
  late final TextEditingController _nssTestCtrl;

  @override
  void initState() {
    super.initState();
    _cedulaTestCtrl = TextEditingController(text: widget.usuarioActual.cedula);
    _nssTestCtrl = TextEditingController(text: widget.usuarioActual.nss);
  }

  @override
  void dispose() {
    _cedulaTestCtrl.dispose();
    _rncTestCtrl.dispose();
    _nssTestCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cedOk = ValidadorDominicano.validarCedulaRD(_cedulaTestCtrl.text);
    final rncOk = ValidadorDominicano.validarRNCDominicano(_rncTestCtrl.text);
    final nssOk = ValidadorDominicano.validarNSSoCarnetARS(_nssTestCtrl.text);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Centro de Verificación Documental y Padrón Dominicano',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Validación algorítmica en tiempo real para auditorías de identidad (JCE), registro tributario de clínicas (DGII) y afiliación (SISALRIL).',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Algoritmo Módulo 10 (Luhn) - Cédula de Identidad y Electoral (JCE)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Multiplica los primeros 10 dígitos por los pesos alternos [1, 2, 1, 2, 1, 2, 1, 2, 1, 2], suma los dígitos de productos >= 10 y verifica (10 - (suma % 10)) % 10.',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _cedulaTestCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Cédula Dominicana (11 dígitos)',
                          suffixIcon: Icon(
                            cedOk ? Icons.verified : Icons.cancel,
                            color: cedOk ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cedOk
                            ? 'CÉDULA VÁLIDA según algoritmo oficial Módulo 10 de la JCE'
                            : 'CÉDULA INVÁLIDA (falla el dígito verificador o longitud)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: cedOk ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Algoritmo Módulo 11 (DGII) - RNC de Hospital / PSS / ARS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Verifica el Registro Nacional de Contribuyentes (9 dígitos) de la Prestadora de Servicios de Salud usando los pesos oficiales [7, 9, 8, 6, 5, 4, 3, 2].',
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _rncTestCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText:
                              'RNC Institucional de PSS / ARS (9 dígitos)',
                          suffixIcon: Icon(
                            rncOk ? Icons.verified : Icons.cancel,
                            color: rncOk ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rncOk
                            ? 'RNC INSTITUCIONAL VÁLIDO según Módulo 11 DGII'
                            : 'RNC INVÁLIDO según Módulo 11 DGII',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: rncOk ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verificación de NSS (SISALRIL) y Número de Póliza ARS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nssTestCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText:
                              'Número de Seguridad Social (NSS) / Carnet',
                          suffixIcon: Icon(
                            nssOk ? Icons.verified : Icons.cancel,
                            color: nssOk ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nssOk
                            ? 'NSS / Póliza válida en estructura de padrón SISALRIL'
                            : 'Formato de NSS inválido',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: nssOk ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}