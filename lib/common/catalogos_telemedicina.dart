class CatalogosTelemedicina {
  static const List<String> arsRepublicaDominicana = [
    'SeNaSa (Régimen Contributivo / Subsidiado)',
    'ARS Primera (Humano)',
    'ARS Universal',
    'Mapfre Salud ARS',
    'ARS Futuro',
    'ARS Yunen',
    'ARS Renacer',
    'ARS Monumental',
    'ARS SEMMA',
    'ARS Reservas',
  ];

  static const Map<String, List<String>> serviciosPorCategoria = {
    'Atención Clínica Especializada': [
      'Consulta médica general',
      'Medicina interna',
      'Pediatría de orientación',
      'Ginecología de seguimiento',
      'Cardiología de seguimiento',
      'Psicología clínica',
      'Nutrición y dietética',
      'Segunda opinión médica',
    ],
    'Programas Asistenciales y Monitoreo': [
      'Control de pacientes crónicos (HTA / Diabetes)',
      'Seguimiento postconsulta',
      'Seguimiento postoperatorio ambulatorio',
      'Revisión de resultados diagnósticos',
      'Orientación médica preventiva',
      'Educación en salud familiar',
      'Monitoreo de adherencia farmacológica',
      'Auditoría de calidad asistencial',
    ],
    'Prestaciones y Órdenes Derivadas': [
      'Receta médica electrónica',
      'Órdenes de laboratorio clínico',
      'Órdenes de imágenes diagnósticas',
      'Referimientos a subespecialidades',
      'Certificación e indicaciones médicas',
      'Programación de control subsecuente',
      'Validación de cobertura PDSS',
      'Autorización electrónica SISALRIL',
    ],
  };

  static const List<String> canalesDisponibles = [
    'Portal Web / App Institucional',
    'Línea de Atención Celular',
    'WhatsApp Oficial PSS',
    'Correo Electrónico',
    'Central Telefónica',
    'Kiosco de Autogestión',
  ];

  static const List<String> plataformasVideo = [
    'Sala Integrada P2P (WebRTC)',
    'MS Teams Clínico',
    'Zoom for Healthcare',
    'Google Meet Enterprise',
  ];

  static const List<String> medicosDisponibles = [
    'Dr. Alejandro Méndez (Medicina Interna - Exeq. 489-19)',
    'Dra. Carmen Peña (Cardiología - Exeq. 312-14)',
    'Dr. Héctor Lantigua (Medicina Familiar - Exeq. 771-20)',
    'Dra. Patricia Gómez (Endocrinología y Nutrición - Exeq. 504-17)',
    'Dra. Rosaura Díaz (Pediatría - Exeq. 619-18)',
  ];

  static const List<String> catalogoLaboratorios = [
    'Hemograma Completo Automatizado',
    'HbA1c (Hemoglobina Glicosilada)',
    'Glucemia Basal en Ayunas',
    'Perfil Lipídico Completo (Colesterol, HDL, LDL, Triglicéridos)',
    'Creatinina Sérica y Filtrado Glomerular',
    'Examen General de Orina (Uroanálisis)',
    'TSH y Perfil Tiroideo Libre',
    'Ácido Úrico y Electrolitos Séricos',
  ];

  static const List<String> catalogoImagenes = [
    'Radiografía de Tórax PA y Lateral',
    'Ecocardiograma Doppler Transtorácico',
    'Sonografía Abdominal Completa',
    'Electrocardiograma de Reposo (12 derivaciones)',
    'MAPA (Monitoreo Ambulatorio de Presión Arterial 24h)',
    'Doppler Carotídeo Bilateral',
  ];

  static const Map<String, double> tarifasPorEspecialidad = {
    'Consulta médica general': 1800.0,
    'Medicina interna': 2500.0,
    'Pediatría de orientación': 2200.0,
    'Ginecología de seguimiento': 2500.0,
    'Cardiología de seguimiento': 3200.0,
    'Psicología clínica': 2400.0,
    'Nutrición y dietética': 2000.0,
    'Segunda opinión médica': 3500.0,
  };
}