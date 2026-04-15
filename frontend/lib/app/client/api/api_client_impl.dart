import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/client/api_client.dart';

// Aquesta classe és l’encarregada de comunicar el frontend amb el backend.
// En aquest cas implementa les operacions d’autenticació
// i tradueix la resposta del servidor en un resultat o en un error entenedor per a l’aplicació.
class ApiClientImpl implements ApiClient {
  // El constructor permet reutilitzar un client HTTP o definir una URL base concreta.
  // Si no es proporciona res, es crea una configuració per defecte segons l’entorn d’execució.
  ApiClientImpl({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? _resolveBaseUrl();

  // Aquest bloc guarda els dos elements principals necessaris per fer peticions:
  // el client HTTP i l’adreça base del backend.
  final http.Client _client;
  final String _baseUrl;

  // Aquest mètode decideix automàticament quina adreça del backend s’ha d’utilitzar.
  // És rellevant perquè l’accés al servidor no és igual en web que en dispositius Android o altres entorns.
  static String _resolveBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000';
      default:
        return 'http://localhost:3000';
    }
  }

  // Aquest mètode envia al backend les dades necessàries per crear un compte nou.
  // Si el servidor confirma el registre, el procés es considera correcte.
  // Si hi ha algun problema, transforma la resposta en un error que la resta de l’aplicació pugui gestionar.
  @override
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
        }),
      );

      // Aquest bloc comprova si el servidor ha acceptat correctament la creació del compte.
      if (response.statusCode == 201) {
        return;
      }

      // Si el registre falla, aquí s’intenta recuperar un missatge clar de la resposta
      // per poder mostrar-lo a l’usuari de manera més útil.
      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message =
          data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut completar el registre';

      throw ApiException(message, statusCode: response.statusCode);
    } catch (error) {
      // Aquest bloc diferencia els errors ja controlats dels errors de connexió
      // o problemes inesperats durant la comunicació amb el servidor.
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
      final response = await _client.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

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

      final message =
          data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut iniciar sessió';

      throw ApiException(message, statusCode: response.statusCode);
    } catch (error) {
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut connectar amb el servidor',
      );
    }
  }

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
}