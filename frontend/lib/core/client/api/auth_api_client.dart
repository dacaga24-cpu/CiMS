import 'package:cims/core/client/api/api_exception.dart';

// Aquesta classe representa la resposta del login.
// Agrupa les dades necessàries per iniciar la sessió a l’aplicació.
class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.userId,
    this.message,
  });

  // Aquest bloc guarda la informació bàsica que el backend retorna
  // quan l’usuari inicia sessió correctament.
  final String token;
  final int userId;
  final String? message;

  // Aquest factory transforma la resposta JSON del servidor en un objecte
  // usable per l’aplicació. També valida les dades clau per evitar continuar
  // amb una sessió incompleta o incorrecta.
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Aquest bloc intenta convertir el userId al format esperat.
    // Es contempla que el backend el pugui retornar en diferents tipus.
    final userIdRaw = json['userId'];
    int? parsedUserId;

    if (userIdRaw is int) {
      parsedUserId = userIdRaw;
    } else if (userIdRaw is num) {
      parsedUserId = userIdRaw.toInt();
    } else if (userIdRaw is String) {
      parsedUserId = int.tryParse(userIdRaw);
    }

    // Si l’identificador de l’usuari no es pot interpretar correctament,
    // es considera que la resposta no és vàlida i es talla el flux.
    if (parsedUserId == null) {
      throw const ApiException('El userId retornat pel servidor no és vàlid');
    }

    // Aquest bloc recupera el token de sessió i comprova que existeixi,
    // ja que és necessari per autenticar les peticions posteriors.
    final token = json['token']?.toString();

    if (token == null || token.isEmpty) {
      throw const ApiException('El token retornat pel servidor no és vàlid');
    }

    return LoginResponse(
      token: token,
      userId: parsedUserId,
      message: json['message'] as String?,
    );
  }
}

// Aquest contracte reuneix les operacions relacionades amb autenticació
// i recuperació de contrasenya.
abstract class AuthApiClient {
  // Aquest mètode envia les dades necessàries per crear un nou compte
  // dins de l’aplicació.
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  // Aquest mètode valida les credencials de l’usuari i retorna
  // la informació necessària per obrir la sessió.
  Future<LoginResponse> login({
    required String email,
    required String password,
  });

  // Aquest mètode inicia el procés de recuperació de contrasenya
  // a partir del correu electrònic de l’usuari.
  Future<String> requestPasswordReset({
    required String email,
  });

  // Aquest mètode completa el canvi de contrasenya utilitzant
  // el token rebut durant el procés de recuperació.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });
}
