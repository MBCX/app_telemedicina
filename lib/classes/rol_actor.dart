enum RolActor {
  paciente,
  admisionPSS,
  medico,
  soporteTI,
  facturacionAuditoria,
}

extension RolActorExtension on RolActor {
  String get etiqueta {
    switch (this) {
      case RolActor.paciente:
        return 'Paciente Afiliado';
      case RolActor.admisionPSS:
        return 'Admisión y Atención (PSS)';
      case RolActor.medico:
        return 'Médico Especialista';
      case RolActor.soporteTI:
        return 'Soporte y Monitoreo Técnico';
      case RolActor.facturacionAuditoria:
        return 'Facturación y Auditoría ARS';
    }
  }

  String get codigo {
    return name;
  }

  static RolActor fromCodigo(String valor) {
    return RolActor.values.firstWhere(
      (e) => e.name == valor,
      orElse: () => RolActor.paciente,
    );
  }
}