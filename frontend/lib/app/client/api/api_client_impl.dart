import 'dart:async';
import 'dart:convert';

import 'package:cims/app/client/api/api_config.dart';
import 'package:cims/app/client/api/api_endpoints.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/region.dart';
import 'package:cims/core/entity/user.dart';
import 'package:cims/core/entity/peak_status.dart';
import 'package:cims/core/entity/ascent.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/entity/user_stats.dart';
import 'package:cims/core/entity/dashboard_summary.dart';
import 'package:cims/core/entity/ascent_upload_photo.dart';
import 'package:cims/core/entity/peaks_page.dart';
import 'package:cims/core/entity/ascent_photo.dart';
import 'package:cims/core/entity/profile_photo_upload.dart';
import 'package:http/http.dart' as http;

// Aquests fitxers separen les peticions de l’API per àmbits funcionals.
// Això permet mantenir aquest arxiu com a punt central sense acumular tota la lògica en un sol lloc.
part 'api_client_impl_auth.dart';
part 'api_client_impl_peaks.dart';
part 'api_client_impl_profile.dart';
part 'api_client_impl_regions.dart';
part 'api_client_impl_peak_status.dart';
part 'api_client_impl_ascents.dart';
part 'api_client_impl_stats.dart';
part 'api_client_impl_monthly_challenge.dart';

// Aquesta classe base centralitza la infraestructura comuna del client d’API.
// Les operacions funcionals es reparteixen en fitxers separats per àmbit
// per mantenir el codi més ordenat i fàcil de seguir.
abstract class _ApiClientBase {
  // Aquest constructor permet crear el client d’API amb la configuració habitual
  // de l’aplicació, però també deixa oberta la possibilitat d’injectar dependències
  // concretes en proves o en altres entorns.
  _ApiClientBase({
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

  // Aquest mètode permet fer peticions PUT JSON sobre endpoints autenticats.
  // S’utilitzarà quan calgui modificar dades ja existents, com l’estat personal d’un cim.
  Future<http.Response> _putJson(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = false,
  }) async {
    final response = await _client
        .put(
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

  // Aquest mètode permet fer peticions DELETE JSON sobre endpoints autenticats.
  // S’utilitza per accions destructives com la desactivació del compte.
  Future<http.Response> _deleteJson(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = false,
  }) async {
    final response = await _client
        .delete(
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
}

// Aquesta classe exposa un únic punt d’entrada cap al client d’API,
// però delega cada bloc funcional a fitxers separats.
class ApiClientImpl extends _ApiClientBase
    with
        _AuthApiClientImplMixin,
        _AscentsApiClientImplMixin,
        _PeaksApiClientImplMixin,
        _ProfileApiClientImplMixin,
        _RegionsApiClientImplMixin,
        _PeakStatusApiClientImplMixin,
        _StatsApiClientImplMixin,
        _MonthlyChallengeApiClientImplMixin
    implements ApiClient {
  // Aquest constructor permet crear el client final de l’API.
  // Reutilitza la configuració comuna definida a la classe base.
  ApiClientImpl({
    super.client,
    super.baseUrl,
  });
}
