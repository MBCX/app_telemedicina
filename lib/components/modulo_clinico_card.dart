import 'package:flutter/material.dart';

class ModuloClinicoCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String responsable;
  final String estadoEtiqueta;
  final bool verificado;
  final Color colorHeader;
  final Widget contenido;

  const ModuloClinicoCard({
    super.key,
    required this.icono,
    required this.titulo,
    required this.responsable,
    required this.estadoEtiqueta,
    required this.verificado,
    required this.colorHeader,
    required this.contenido,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: verificado ? Colors.green.shade300 : Colors.grey.shade300,
          width: verificado ? 2 : 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // Elimina la linea del ExpansionTile
        ),
        child: ExpansionTile(
          initiallyExpanded: !verificado, // Auto-expande si no está completado
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: verificado ? Colors.green.shade50 : Colors.white,
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: verificado ? Colors.green.shade100 : colorHeader.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              verificado ? Icons.check_circle : icono,
              color: verificado ? Colors.green.shade700 : colorHeader,
              size: 28,
            ),
          ),
          title: Text(
            titulo,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: verificado ? Colors.green.shade800 : Colors.black87,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Responsable: $responsable',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: verificado ? Colors.green.shade600 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  verificado ? Icons.verified : Icons.schedule,
                  color: verificado ? Colors.white : Colors.black54,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  estadoEtiqueta.toUpperCase(),
                  style: TextStyle(
                    color: verificado ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: contenido,
            ),
          ],
        ),
      ),
    );
  }
}