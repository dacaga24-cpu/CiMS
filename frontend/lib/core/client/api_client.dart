// Aquesta classe representa un error relacionat amb la comunicació amb l’API.
// Serveix per traslladar a l’aplicació un missatge clar sobre què ha fallat
// i, si es disposa d’aquesta informació, el codi d’estat retornat pel servidor.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  // Aquest bloc guarda la informació bàsica de l’error
  // perquè després es pugui mostrar o gestionar des de la interfície.
  final String message;
  final int? statusCode;

  // Aquest mètode retorna el missatge de l’error en format text.
  @override
  String toString() => message;
}

// Aquesta classe representa la resposta que retorna el servidor
// quan l’usuari inicia sessió correctament.
// Agrupa la informació necessària per continuar amb la sessió dins de l’aplicació.
class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.userId,
    this.message,
  });

  // Aquest bloc recull les dades principals de la resposta de login:
  // el token de sessió, l’identificador de l’usuari i un missatge opcional.
  final String token;
  final int userId;
  final String? message;

  // Aquest constructor transforma la resposta rebuda del backend
  // en un objecte que l’aplicació pugui utilitzar fàcilment.
  // També comprova que les dades més importants siguin vàlides abans de continuar.
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userIdRaw = json['userId'];
    int? parsedUserId;

    if (userIdRaw is int) {
      parsedUserId = userIdRaw;
    } else if (userIdRaw is num) {
      parsedUserId = userIdRaw.toInt();
    } else if (userIdRaw is String) {
      parsedUserId = int.tryParse(userIdRaw);
    }

    if (parsedUserId == null) {
      throw const ApiException('El userId retornat pel servidor no és vàlid');
    }

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

// Aquesta classe abstracta defineix el contracte bàsic del client d’API.
// És rellevant perquè estableix quines operacions ha de poder fer qualsevol
// implementació encarregada de comunicar-se amb el backend.
abstract class ApiClient {
  // Aquest mètode defineix l’operació de registre d’un nou usuari.
  // Rep les dades necessàries per crear el compte i deixa clar
  // que qualsevol client d’API haurà d’implementar aquest comportament.
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  // Aquest mètode defineix l’operació d’inici de sessió.
  // Rep les credencials de l’usuari i retorna la informació necessària
  // per continuar amb la sessió oberta dins de l’aplicació.
  Future<LoginResponse> login({
    required String email,
    required String password,
  });
}
