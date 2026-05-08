part of 'api_client_impl.dart';

// Aquest mixin agrupa les operacions relacionades amb el perfil
// de l’usuari autenticat dins del client d’API.
mixin _ProfileApiClientImplMixin on _ApiClientBase implements ProfileApiClient {
  // Aquest mètode recupera el perfil de l’usuari autenticat.
  // El seu objectiu és obtenir les dades necessàries per mostrar
  // la informació personal i l’estat actual de la sessió dins de l’aplicació.
  @override
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

  // Aquest mètode actualitza les dades bàsiques del perfil.
  // Envia el nom i cognoms al backend i retorna l’usuari actualitzat.
  @override
  Future<User> updateUserProfile({
    required String firstName,
    required String lastName,
  }) async {
    try {
      final response = await _putJson(
        ApiEndpoints.userProfile,
        body: {
          'firstName': firstName,
          'lastName': lastName,
        },
        requiresAuth: true,
      );

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
          'No s\'ha pogut actualitzar el perfil';

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

  // Aquest mètode envia el canvi de contrasenya al backend.
  // No retorna cap entitat perquè només cal confirmar que l’operació s’ha completat.
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _putJson(
        ApiEndpoints.changePassword,
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        return;
      }

      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut canviar la contrasenya';

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

  // Aquest mètode envia la petició de desactivació del compte al backend.
  // Si la contrasenya és correcta, el compte queda desactivat i la sessió es podrà tancar.
  @override
  Future<void> deleteAccount({
    required String password,
  }) async {
    try {
      final response = await _deleteJson(
        ApiEndpoints.deleteAccount,
        body: {
          'password': password,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }

      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut desactivar el compte';

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
  // Aquest mètode demana al backend una URL temporal per pujar la foto de perfil.
  // La resposta inclou la ruta final i els headers obligatoris per fer la pujada.
  @override
  Future<ProfilePhotoSignedUploadUrl> createProfilePhotoSignedUploadUrl({
    required String mimeType,
  }) async {
    try {
      final response = await _postJson(
        ApiEndpoints.profilePhotoSignedUploadUrl,
        body: {
          'mimeType': mimeType,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _tryParseJson(response.body);

        if (data == null) {
          throw ApiException(
            'La resposta de pujada de foto de perfil no és vàlida',
            statusCode: response.statusCode,
          );
        }

        return ProfilePhotoSignedUploadUrl.fromJson(data);
      }

      final data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut preparar la pujada de la foto de perfil';

      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut preparar la pujada de la foto de perfil',
      );
    }
  }

  // Aquest mètode puja la imatge directament a GCS mitjançant la URL temporal.
  // No fa servir el token de sessió perquè la URL ja incorpora el permís temporal.
  @override
  Future<void> uploadProfilePhotoBytes({
    required String uploadUrl,
    required List<int> bytes,
    required Map<String, String> headers,
  }) async {
    try {
      final response = await _client
          .put(
            Uri.parse(uploadUrl),
            headers: headers,
            body: bytes,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return;
      }

      throw ApiException(
        'No s\'ha pogut pujar la foto de perfil',
        statusCode: response.statusCode,
      );
    } on TimeoutException {
      throw const ApiException(
        'La pujada de la foto ha trigat massa',
      );
    } catch (error) {
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut pujar la foto de perfil',
      );
    }
  }

  // Aquest mètode confirma al backend la foto que s’ha pujat correctament.
  // Retorna l’usuari actualitzat amb la URL de visualització de la nova imatge.
  @override
  Future<User> setProfilePhoto({
    required String storagePath,
  }) async {
    try {
      final response = await _putJson(
        ApiEndpoints.profilePhoto,
        body: {
          'storagePath': storagePath,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = _tryParseJson(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta de la foto de perfil no és vàlida',
            statusCode: 200,
          );
        }

        return User.fromJson(data);
      }

      final data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut actualitzar la foto de perfil';

      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut actualitzar la foto de perfil',
      );
    }
  }

  // Aquest mètode elimina la foto de perfil actual.
  // El backend retorna el perfil actualitzat sense URL de foto.
  @override
  Future<User> deleteProfilePhoto() async {
    try {
      final response = await _deleteJson(
        ApiEndpoints.profilePhoto,
        body: {},
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final data = _tryParseJson(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta d\'eliminació de foto no és vàlida',
            statusCode: 200,
          );
        }

        return User.fromJson(data);
      }

      final data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut eliminar la foto de perfil';

      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut eliminar la foto de perfil',
      );
    }
  }
}
