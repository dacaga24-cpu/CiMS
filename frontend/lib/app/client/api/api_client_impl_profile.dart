part of 'api_client_impl.dart';

// Aquest mixin agrupa les operacions relacionades amb el perfil
// de l’usuari autenticat dins del client d’API.
mixin _ProfileApiClientImplMixin on _ApiClientBase {
  // Aquest mètode recupera el perfil de l’usuari autenticat.
  // El seu objectiu és obtenir les dades necessàries per mostrar
  // la informació personal i l’estat actual de la sessió dins de l’aplicació.
  Future<User> getUserProfile() async {
    try {
      final response = await _getJson(
        ApiEndpoints.userProfile,
        requiresAuth: true,
      );

      // Si la resposta és correcta, es transforma el JSON rebut
      // en l’objecte User que farà servir el frontend.
      if (response.statusCode == 200) {
        final Map<String, dynamic>? data = _tryParseJson(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta del servidor no és vàlida',
            statusCode: 200,
          );
        }

        return User.fromJson(data);
      }

      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut recuperar el perfil';

      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut connectar amb el servidor',
      );
    }
  }
}
