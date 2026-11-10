class MensajeTeleconsulta {
  final int? id;
  final String citaId;
  final String autor;
  final String rolAutor;
  final String texto;
  final DateTime fechaHora;

  const MensajeTeleconsulta({
    this.id,
    required this.citaId,
    required this.autor,
    required this.rolAutor,
    required this.texto,
    required this.fechaHora,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'cita_id': citaId,
      'autor': autor,
      'rol_autor': rolAutor,
      'texto': texto,
      'fecha_hora': fechaHora.toIso8601String(),
    };
  }

  factory MensajeTeleconsulta.fromMap(Map<String, dynamic> map) {
    return MensajeTeleconsulta(
      id: map['id'] as int?,
      citaId: map['cita_id'] as String,
      autor: map['autor'] as String,
      rolAutor: map['rol_autor'] as String,
      texto: map['texto'] as String,
      fechaHora: DateTime.parse(map['fecha_hora'] as String),
    );
  }
}