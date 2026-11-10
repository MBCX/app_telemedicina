import 'rol_actor.dart';

class UsuarioSistema {
  final String cedula;
  final String nombre;
  final String ars;
  final String nss;
  final String email;
  final String telefono;
  final String passwordHash;
  final RolActor rol;

  const UsuarioSistema({
    required this.cedula,
    required this.nombre,
    required this.ars,
    required this.nss,
    required this.email,
    required this.telefono,
    required this.passwordHash,
    required this.rol,
  });

  Map<String, dynamic> toMap() {
    return {
      'cedula': cedula,
      'nombre': nombre,
      'ars': ars,
      'nss': nss,
      'email': email,
      'telefono': telefono,
      'password_hash': passwordHash,
      'rol': rol.codigo,
    };
  }

  factory UsuarioSistema.fromMap(Map<String, dynamic> map) {
    return UsuarioSistema(
      cedula: map['cedula'] as String,
      nombre: map['nombre'] as String,
      ars: map['ars'] as String,
      nss: map['nss'] as String,
      email: map['email'] as String,
      telefono: map['telefono'] as String,
      passwordHash: map['password_hash'] as String,
      rol: RolActorExtension.fromCodigo(map['rol'] as String),
    );
  }
}