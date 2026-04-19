import 'dart:async';
import 'dart:convert';

import 'package:cims/app/client/api/api_config.dart';
import 'package:cims/app/client/api/api_endpoints.dart';
import 'package:http/http.dart' as http;

import '../../../core/client/api_client.dart';


// Aquesta classe s’encarrega de comunicar el frontend amb el backend.
// Implementa les operacions principals d’autenticació
// i transforma les respostes del servidor en resultats útils o errors entenedors per a l’aplicació.
class ApiClientImpl implements ApiClient {
  // El constructor permet reutilitzar un client HTTP o definir una URL base concreta.
  // Si no es proporciona res, es fa servir la configuració centralitzada del projecte.
  ApiClientImpl({
    http.Client? client,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  // Aquest bloc guarda els elements bàsics necessaris per fer peticions:
  // el client HTTP i l’adreça base del backend.
  final http.Client _client;
  final String _baseUrl;

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
      final response = await _client
          .post(
            Uri.parse('$_baseUrl${ApiEndpoints.register}'),
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'firstName': firstName,
              'lastName': lastName,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      // Aquest bloc comprova si el servidor ha acceptat correctament la creació del compte.
      if (response.statusCode == 201) {
        return;
      }

      // Si el registre falla, aquí s’intenta recuperar un missatge clar de la resposta
      // per poder mostrar-lo a l’usuari de manera més útil.
      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut completar el registre';

      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      // Aquest error es retorna quan el servidor triga massa a respondre.
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      // Aquest bloc diferencia els errors ja controlats dels errors de connexió
      // o problemes inesperats durant la comunicació amb el servidor.
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut connectar amb el servidor',
      );
    }
  }

  // Aquest mètode envia les credencials de l’usuari per iniciar sessió.
  // Si la resposta és correcta, retorna la informació necessària per continuar
  // amb la sessió oberta dins de l’aplicació.
  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl${ApiEndpoints.login}'),
            headers: const {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      // Aquest bloc valida que la resposta correcta del servidor
      // contingui informació usable per l’aplicació.
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

      // Si el login falla, es prova d’obtenir un missatge d’error clar
      // per mostrar-lo a l’usuari.
      final Map<String, dynamic>? data = _tryParseJson(response.body);

      final message = data?['error']?.toString() ??
          data?['message']?.toString() ??
          'No s\'ha pogut iniciar sessió';

      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      // Aquest error es retorna quan el servidor no respon dins del temps previst.
      throw const ApiException(
        'El servidor no respon. Torna-ho a provar',
      );
    } catch (error) {
      // Aquest bloc conserva els errors ja controlats i converteix la resta
      // en un missatge general de connexió.
      if (error is ApiException) rethrow;

      throw const ApiException(
        'No s\'ha pogut connectar amb el servidor',
      );
    }
  }

  // Aquest mètode intenta interpretar el text rebut del servidor com a JSON.
  // És útil per llegir missatges d’èxit o d’error sense provocar fallades
  // si la resposta arriba buida o amb un format inesperat.
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