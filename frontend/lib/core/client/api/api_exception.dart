// Aquest error representa un problema durant la comunicació amb l’API.
// Permet traslladar un missatge clar i, si es coneix, el codi HTTP associat.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  // Aquest bloc guarda la informació principal de l’error
  // perquè després es pugui gestionar o mostrar a l’usuari.
  final String message;
  final int? statusCode;

  // Aquest camp opcional porta un codi simbòlic emès pel backend
  // (com WEATHER_PROVIDER_UNAVAILABLE) perquè els controllers puguin
  // distingir errors concrets sense haver d'inspeccionar el missatge
  // —el text es pot reescriure en català sense que la lògica del
  // client es trenqui.
  final String? code;

  // Aquest mètode retorna el text de l’error en un format simple,
  // útil quan es necessita mostrar-lo directament.
  @override
  String toString() => message;
}

// Aquest error indica que la sessió ja no és vàlida.
// Serveix per diferenciar un 401 d’altres errors d’API.
class ApiUnauthorizedException extends ApiException {
  // Aquest constructor crea directament un error específic de sessió caducada
  // perquè l’aplicació el pugui tractar de manera diferent si convé.
  const ApiUnauthorizedException([
    super.message = 'La sessió ha caducat',
  ]) : super(statusCode: 401);
}
