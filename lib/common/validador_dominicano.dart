class ValidadorDominicano {
  static bool validarCedulaRD(String cedulaRaw) {
    final cedula = cedulaRaw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cedula.length != 11) return false;
    final serie = int.tryParse(cedula.substring(0, 3)) ?? 0;
    if (serie == 0) return false;
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cedula)) return false;

    const pesos = [1, 2, 1, 2, 1, 2, 1, 2, 1, 2];
    int suma = 0;
    for (int i = 0; i < 10; i++) {
      int digito = int.parse(cedula[i]);
      int producto = digito * pesos[i];
      if (producto >= 10) {
        producto = (producto ~/ 10) + (producto % 10);
      }
      suma += producto;
    }
    int digitoVerificadorCalculado = (10 - (suma % 10)) % 10;
    int digitoVerificadorReal = int.parse(cedula[10]);
    return digitoVerificadorCalculado == digitoVerificadorReal;
  }

  static String generarCedulaValida(String primeros10Digitos) {
    final base = primeros10Digitos.replaceAll(RegExp(r'[^0-9]'), '');
    if (base.length != 10) return '001-1234567-8';
    const pesos = [1, 2, 1, 2, 1, 2, 1, 2, 1, 2];
    int suma = 0;
    for (int i = 0; i < 10; i++) {
      int prod = int.parse(base[i]) * pesos[i];
      if (prod >= 10) prod = (prod ~/ 10) + (prod % 10);
      suma += prod;
    }
    int verificador = (10 - (suma % 10)) % 10;
    return '${base.substring(0, 3)}-${base.substring(3, 10)}-$verificador';
  }

  static bool validarRNCDominicano(String rncRaw) {
    final rnc = rncRaw.replaceAll(RegExp(r'[^0-9]'), '');
    if (rnc.length != 9) return false;
    const pesos = [7, 9, 8, 6, 5, 4, 3, 2];
    int suma = 0;
    for (int i = 0; i < 8; i++) {
      suma += int.parse(rnc[i]) * pesos[i];
    }
    int resto = suma % 11;
    int digito;
    if (resto == 0) {
      digito = 2;
    } else if (resto == 1) {
      digito = 1;
    } else {
      digito = 11 - resto;
    }
    return digito == int.parse(rnc[8]);
  }

  static bool validarNSSoCarnetARS(String nssRaw) {
    final limpio = nssRaw.replaceAll(RegExp(r'[^0-9]'), '');
    if (limpio.length < 8 || limpio.length > 12) return false;
    if (RegExp(r'^0+$').hasMatch(limpio)) return false;
    return true;
  }

  static bool validarNCF(String ncfRaw) {
    final limpio = ncfRaw.trim().toUpperCase();
    return RegExp(r'^(B|E)[0-9]{10,12}$').hasMatch(limpio);
  }
}