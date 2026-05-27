import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

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
import 'package:cims/core/entity/ascent_photo_gallery.dart';
import 'package:cims/core/entity/peak_weather.dart';
import 'package:cims/core/entity/peak_hourly_weather.dart';
import 'package:http/http.dart' as http;

// Aquests fitxers separen les peticions de l’API per àmbits funcionals.
// Això manté el client principal ordenat i facilita la lectura del projecte.
part 'api_client_impl_auth.dart';
part 'api_client_impl_peaks.dart';
part 'api_client_impl_profile.dart';
part 'api_client_impl_regions.dart';
part 'api_client_impl_peak_status.dart';
part 'api_client_impl_ascents.dart';
part 'api_client_impl_stats.dart';
part 'api_client_impl_monthly_challenge.dart';
part 'api_client_impl_weather.dart';

// Aquesta classe base centralitza la infraestructura comuna del client d’API.
// Les operacions funcionals es reparteixen en fitxers separats per àmbit.
abstract class _ApiClientBase {
  // Aquest constructor permet crear el client amb la configuració habitual.
  // També facilita injectar dependències concretes en proves o altres entorns.
  _ApiClientBase({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  // Aquest bloc guarda els elements bàsics per fer peticions al backend.
  final http.Client _client;

  // Aquesta variable guarda l’adreça base del servidor.
  // S’utilitza per construir totes les URLs de l’API de manera centralitzada.
  final String _baseUrl;

  // Aquest mètode permet fer peticions POST amb cos JSON.
  // Si l’endpoint és protegit, afegeix automàticament el token de sessió.
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
        .timeout(const Duration(seconds: 20));

    await _handleUnauthorizedIfNeeded(
      response,
      requiresAuth: requiresAuth,
    );

    return response;
  }

  // Aquest mètode permet fer peticions PUT amb cos JSON.
  // S’utilitza per modificar dades existents al backend.
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
        .timeout(const Duration(seconds: 20));

    await _handleUnauthorizedIfNeeded(
      response,
      requiresAuth: requiresAuth,
    );

    return response;
  }

  // Aquest mètode encapsula les peticions GET de l’aplicació.
  // Pot enviar el token quan és obligatori o només quan existeix per enriquir rutes públiques.
  Future<http.Response> _getJson(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool requiresAuth = false,
    bool attachTokenIfAvailable = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );

    final response = await _client
        .get(
          uri,
          headers: await _buildHeaders(
            requiresAuth: requiresAuth,
            attachTokenIfAvailable: attachTokenIfAvailable,
          ),
        )
        .timeout(const Duration(seconds: 20));

    await _handleUnauthorizedIfNeeded(
      response,
      requiresAuth: requiresAuth,
    );

    return response;
  }

  // Aquest mètode construeix els headers comuns de les peticions.
  // Gestiona quan cal exigir token i quan només s’ha d’afegir si ja existeix.
  Future<Map<String, String>> _buildHeaders({
    bool requiresAuth = false,
    bool attachTokenIfAvailable = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = await AppSession.storage.readToken();

      // Si no hi ha token, la sessió es considera no vàlida.
      // L’aplicació neteja la sessió local i força el retorn al login.
      if (token == null || token.isEmpty) {
        await AppSession.handleUnauthorized();
        throw const ApiUnauthorizedException();
      }

      headers['Authorization'] = 'Bearer $token';
      return headers;
    }

    if (attachTokenIfAvailable) {
      final token = await AppSession.storage.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // Aquest mètode centralitza el comportament davant d’un 401 en rutes protegides.
  // Quan el token ja no és vàlid, neteja la sessió i informa l’aplicació.
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
  // Si el format no és vàlid, retorna null perquè el servei pugui gestionar l’error.
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
  // És útil per processar col·leccions rebudes del backend.
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

  // Aquest mètode elimina una ascensió concreta de l’usuari autenticat.
  // El backend comprova la propietat i actualitza els estats relacionats.
  Future<void> deleteAscent(int ascentId);

  // Aquest mètode permet fer peticions DELETE amb cos JSON opcional.
  // S’utilitza per accions destructives com eliminar fotos, ascensions o el compte.
  Future<http.Response> _deleteJson(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final response = await _client
        .delete(
          Uri.parse('$_baseUrl$endpoint'),
          headers: await _buildHeaders(requiresAuth: requiresAuth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    await _handleUnauthorizedIfNeeded(
      response,
      requiresAuth: requiresAuth,
    );

    return response;
  }
}

// Aquesta classe exposa un únic punt d’entrada cap al client d’API.
// Cada bloc funcional es delega als mixins corresponents.
class ApiClientImpl extends _ApiClientBase
    with
        _AuthApiClientImplMixin,
        _AscentsApiClientImplMixin,
        _PeaksApiClientImplMixin,
        _ProfileApiClientImplMixin,
        _RegionsApiClientImplMixin,
        _PeakStatusApiClientImplMixin,
        _StatsApiClientImplMixin,
        _MonthlyChallengeApiClientImplMixin,
        _WeatherApiClientImplMixin
    implements ApiClient {
  // Aquest constructor crea el client final de l’API.
  // Reutilitza la configuració comuna definida a la classe base.
  ApiClientImpl({
    super.client,
    super.baseUrl,
  });
}
