// Aquest error representa un problema durant la comunicació amb l’API.
// Permet traslladar un missatge clar i, si es coneix, el codi HTTP associat.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

// Aquest error indica que la sessió ja no és vàlida.
// Serveix per diferenciar un 401 d’altres errors d’API.
class ApiUnauthorizedException extends ApiException {
  const ApiUnauthorizedException([
    super.message = 'La sessió ha caducat',
  ]) : super(statusCode: 401);
}
