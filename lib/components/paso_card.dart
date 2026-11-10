import 'package:flutter/material.dart';

class PasoCard extends StatelessWidget {
  final int numero;
  final String titulo;
  final String actor;
  final bool completado;
  final Color colorHeader;
  final Widget contenido;

  const PasoCard({
    super.key,
    required this.numero,
    required this.titulo,
    required this.actor,
    required this.completado,
    required this.colorHeader,
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: completado ? Colors.green : Colors.grey.shade300,
          width: completado ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorHeader,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Text(
                    '$numero',
                    style: TextStyle(
                      color: colorHeader,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        actor,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  completado
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: completado ? Colors.greenAccent : Colors.white70,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: contenido,
          ),
        ],
      ),
    );
  }
}