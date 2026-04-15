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

class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.userId,
    this.message,
  });

  final String token;
  final int userId;
  final String? message;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      userId: json['userId'] as int,
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

  Future<LoginResponse> login({
    required String email,
    required String password,
  });

}
