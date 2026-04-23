import 'dart:async';
import 'dart:convert';
import 'package:cims/app/client/api/api_config.dart';
import 'package:cims/app/client/api/api_endpoints.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/region.dart';
import 'package:cims/core/entity/user.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:http/http.dart' as http;

// Aquesta classe s’encarrega de comunicar el frontend amb el backend.
// Implementa les operacions principals d’autenticació
// i transforma les respostes del servidor en resultats útils o errors entenedors per a l’aplicació.
class ApiClientImpl implements ApiClient {
  // Aquest constructor permet crear el client d’API amb la configuració habitual
  // de l’aplicació, però també deixa oberta la possibilitat d’injectar dependències
  // concretes en proves o en altres entorns.
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

  // Aquest mètode envia al backend les dades del registre d’un nou usuari.
  // Si el servidor accepta la petició, el procés es considera completat;
  // en cas contrari, es transforma l’error en un missatge útil per a l’aplicació.
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

  // Aquest mètode valida les credencials de l’usuari contra el backend.
  // Si el procés és correcte, retorna la informació necessària
  // per iniciar la sessió dins de l’aplicació.
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

  // Aquest mètode recupera el catàleg de cims i permet aplicar criteris
  // de cerca o filtratge per retornar només els resultats que interessen a l’usuari.
  @override
  Future<List<Peak>> getPeaks({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
  }) async {
    try {
      final response = await _getJson(
        ApiEndpoints.peaks,
        queryParameters: {
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (regionId != null) 'regionId': regionId.toString(),
          if (minAltitude != null) 'minAltitude': minAltitude.toString(),
          if (maxAltitude != null) 'maxAltitude': maxAltitude.toString(),
        },
      );

      // Si la resposta és correcta, es valida que el cos sigui una llista
      // i es transforma cada element en un objecte Peak del sistema.
      if (response.statusCode == 200) {
        final data = _tryParseJsonList(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta del catàleg no és vàlida',
            statusCode: 200,
          );
        }

        return data
            .whereType<Map<String, dynamic>>()
            .map(Peak.fromJson)
            .toList();
      }

      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut carregar el catàleg de cims';

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

  // Aquest mètode recupera la llista de comarques des del backend.
  // Si la resposta és correcta, transforma les dades rebudes en objectes Region
  // perquè la resta de l’aplicació les pugui utilitzar.
  @override
  Future<List<Region>> getRegions() async {
    try {
      final response = await _getJson(ApiEndpoints.regions);

      // Si el servidor respon correctament, es valida que el cos sigui una llista
      // i es converteix cada element en una comarca del sistema.
      if (response.statusCode == 200) {
        final data = _tryParseJsonList(response.body);

        // Aquest control evita continuar amb dades mal formades encara que el servidor
        // hagi respost amb èxit.
        if (data == null) {
          throw const ApiException(
            'La resposta de les comarques no és vàlida',
            statusCode: 200,
          );
        }

        return data
            .whereType<Map<String, dynamic>>()
            .map(Region.fromJson)
            .toList();
      }

      // Si la petició no ha anat bé, s’intenta recuperar un missatge d’error útil
      // per mostrar una resposta més clara a l’usuari.
      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'han pogut carregar les comarques';

      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      // Aquest cas controla quan el servidor tarda massa a respondre.
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      // Si l’error ja estava controlat com a ApiException, es conserva tal com està.
      // En qualsevol altre cas, es retorna un missatge genèric de connexió.
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

  // Aquest mètode intenta convertir el cos de la resposta en una llista JSON.
  // És útil per processar col·leccions com el catàleg de cims sense barrejar aquesta lògica amb la UI.
  List<dynamic>? _tryParseJsonList(String body) {
    if (body.isEmpty) return null;

    try {
      final decoded = jsonDecode(body);
      if (decoded is List<dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Aquest mètode recupera el perfil de l’usuari autenticat.
  // El seu objectiu és obtenir les dades necessàries per mostrar
  // la informació personal i l’estat actual de la sessió dins de l’aplicació.
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
    Map<String, String>? queryParameters,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );

    final response = await _client
        .get(
          uri,
          headers: await _buildHeaders(requiresAuth: requiresAuth),
        )
        .timeout(const Duration(seconds: 10));

    await _handleUnauthorizedIfNeeded(
      response,
      requiresAuth: requiresAuth,
    );

    return response;
  }

  // Aquest mètode recupera el detall d’un cim concret a partir del seu identificador.
  // És útil per carregar la pantalla de detall i admet tant una resposta directa
  // com una resposta on el cim arribi dins del camp "peak".
  @override
  Future<Peak> getPeakById(int peakId) async {
    try {
      final response = await _getJson(
        ApiEndpoints.peakById(peakId),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic>? data = _tryParseJson(response.body);

        if (data == null) {
          throw const ApiException(
            'La resposta del detall del cim no és vàlida',
            statusCode: 200,
          );
        }

        final dynamic peakRaw = data['peak'];
        final Map<String, dynamic> peakJson =
            peakRaw is Map<String, dynamic> ? peakRaw : data;

        return Peak.fromJson(peakJson);
      }

      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut carregar el detall del cim';

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