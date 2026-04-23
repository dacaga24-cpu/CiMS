import 'package:cims/core/client/api/api_exception.dart';

// Aquesta classe representa la resposta del login.
// Agrupa les dades necessàries per iniciar la sessió a l’aplicació.
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

// Aquest contracte reuneix les operacions relacionades amb autenticació
// i recuperació de contrasenya.
abstract class AuthApiClient {
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

  Future<String> requestPasswordReset({
    required String email,
  });

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });
}
