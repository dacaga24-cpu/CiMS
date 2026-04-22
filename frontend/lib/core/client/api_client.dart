import 'package:cims/core/entity/user.dart';

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

    // Aquest bloc intenta adaptar el valor de userId al format enter
    // encara que el backend l’enviï amb un tipus lleugerament diferent.
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

  // Aquest mètode defineix la recuperació del perfil de l’usuari autenticat.
  // És una crida protegida i serveix per validar que la sessió realment funciona
  // més enllà del login i del guardat local del token.
  Future<User> getUserProfile();

  // Aquest mètode defineix la petició inicial de recuperació de contrasenya.
  // Rep el correu de l’usuari i permet iniciar el procés sense exposar
  // des de la pantalla els detalls de comunicació amb el backend.
  Future<String> requestPasswordReset({
    required String email,
  });

  // Aquest mètode defineix l’enviament de la nova contrasenya.
  // Rep el token del procés de recuperació i la nova contrasenya
  // perquè el backend pugui validar l’acció i aplicar el canvi.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });
}

// Aquest error indica que la sessió ja no és vàlida per accedir a un endpoint protegit.
// Permet diferenciar un 401 de sessió caducada d’altres errors d’API.
class ApiUnauthorizedException extends ApiException {
  const ApiUnauthorizedException([
    super.message = 'La sessió ha caducat',
  ]) : super(statusCode: 401);
}