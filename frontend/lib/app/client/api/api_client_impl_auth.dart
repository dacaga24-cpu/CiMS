part of 'api_client_impl.dart';

// Aquest mixin agrupa totes les operacions d’autenticació
// i recuperació de contrasenya del client d’API.
mixin _AuthApiClientImplMixin on _ApiClientBase {
  // Aquest mètode envia al backend les dades del registre d’un nou usuari.
  // Si el servidor accepta la petició, el procés es considera completat;
  // en cas contrari, es transforma l’error en un missatge útil per a l’aplicació.
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _postJson(
        ApiEndpoints.register,
        body: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
        },
      );

      // Si el backend confirma el registre amb el codi esperat,
      // el procés es considera completat correctament.
      if (response.statusCode == 201) {
        return;
      }

      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut completar el registre';

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

  // Aquest mètode valida les credencials de l’usuari contra el backend.
  // Si el procés és correcte, retorna la informació necessària
  // per iniciar la sessió dins de l’aplicació.
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _postJson(
        ApiEndpoints.login,
        body: {
          'email': email,
          'password': password,
        },
      );

      // Quan el login és correcte, la resposta del servidor es transforma
      // en un objecte útil per a la resta de l’aplicació.
      if (response.statusCode == 200) {
        final Map<String, dynamic>? data = _tryParseJson(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta del servidor no és vàlida',
            statusCode: 200,
          );
        }

        return LoginResponse.fromJson(data);
      }

      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut iniciar sessió';

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

  // Aquest mètode envia la petició per iniciar la recuperació de contrasenya.
  // Si el backend retorna un missatge, es reutilitza per mostrar una confirmació neutra a l’usuari.
  Future<String> requestPasswordReset({
    required String email,
  }) async {
    try {
      final response = await _postJson(
        ApiEndpoints.forgotPassword,
        body: {
          'email': email,
        },
      );

      final Map<String, dynamic>? data = _tryParseJson(response.body);

      // Si el backend accepta la petició, es retorna un missatge neutre
      // per mantenir el flux segur i coherent de recuperació de contrasenya.
      if (response.statusCode == 200) {
        return data?['message']?.toString() ??
            'Si el correu existeix, t\'hem enviat un enllaç per restablir la contrasenya';
      }

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut processar la recuperació de contrasenya';

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

  // Aquest mètode envia la nova contrasenya juntament amb el token rebut al correu.
  // Si el backend valida l’enllaç i actualitza la contrasenya, el procés es dona per completat.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _postJson(
        ApiEndpoints.resetPassword,
        body: {
          'token': token,
          'newPassword': newPassword,
        },
      );

      if (response.statusCode == 200) {
        return;
      }

      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut restablir la contrasenya';

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
