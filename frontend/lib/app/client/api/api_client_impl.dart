import 'dart:async';
import 'dart:convert';
import 'package:cims/app/client/api/api_config.dart';
import 'package:cims/app/client/api/api_endpoints.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/entity/user.dart';
import 'package:http/http.dart' as http;

// Aquesta classe s’encarrega de comunicar el frontend amb el backend.
// Implementa les operacions principals d’autenticació
// i transforma les respostes del servidor en resultats útils o errors entenedors per a l’aplicació.
class ApiClientImpl implements ApiClient {
  ApiClientImpl({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  // Aquest bloc guarda els elements bàsics necessaris per fer peticions:
  // el client HTTP real i l’adreça base del backend.
  final http.Client _client;

  // Aquesta variable guarda l’adreça base del servidor per construir
  // totes les URLs de l’API de manera centralitzada.
  final String _baseUrl;

  @override
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

  @override
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
  @override
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
  @override
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

  // Aquest mètode permet fer peticions POST JSON tant públiques com autenticades.
  // Si l’endpoint és protegit, afegeix automàticament el token guardat a la sessió.
  Future<http.Response> _postJson(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = false,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl$endpoint'),
          headers: await _buildHeaders(requiresAuth: requiresAuth),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    await _handleUnauthorizedIfNeeded(
      response,
      requiresAuth: requiresAuth,
    );

    return response;
  }

  // Aquest mètode construeix els headers comuns de les peticions.
  // Quan la petició necessita autenticació, afegeix el token Bearer.
  Future<Map<String, String>> _buildHeaders({
    bool requiresAuth = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (!requiresAuth) {
      return headers;
    }

    final token = await AppSession.storage.readToken();

    // Si no hi ha token disponible, l’aplicació tracta aquesta situació
    // com una sessió no vàlida i força la sortida de l’usuari.
    if (token == null || token.isEmpty) {
      await AppSession.handleUnauthorized();
      throw const ApiUnauthorizedException();
    }

    headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  // Aquest bloc centralitza el comportament davant d’un 401 en endpoints protegits.
  // A curt termini, és suficient: es neteja la sessió local i es redirigeix l’usuari a login.
  Future<void> _handleUnauthorizedIfNeeded(
    http.Response response, {
    required bool requiresAuth,
  }) async {
    if (!requiresAuth) return;
    if (response.statusCode != 401) return;

    await AppSession.handleUnauthorized();
    throw const ApiUnauthorizedException();
  }

  // Aquest mètode intenta convertir el cos de la resposta en un mapa JSON.
  // Si el servidor no retorna un format vàlid, es retorna null per poder gestionar-ho sense trencar l’app.
  Map<String, dynamic>? _tryParseJson(String body) {
    if (body.isEmpty) return null;

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User> getUserProfile() async {
    try {
      final response = await _getJson(
        ApiEndpoints.profile,
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

  // Aquest mètode encapsula les peticions GET de l’aplicació
  // per reutilitzar la mateixa construcció d’headers i el mateix control d’errors d’autenticació.
  Future<http.Response> _getJson(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl$endpoint'),
          headers: await _buildHeaders(requiresAuth: requiresAuth),
        )
        .timeout(const Duration(seconds: 10));

    await _handleUnauthorizedIfNeeded(
      response,
      requiresAuth: requiresAuth,
    );

    return response;
  }
}