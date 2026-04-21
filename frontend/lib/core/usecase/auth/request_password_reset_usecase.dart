import 'package:cims/core/client/api_client.dart';

class RequestPasswordResetUseCase {
  const RequestPasswordResetUseCase({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<String> execute({
    required String email,
  }) {
    return _apiClient.requestPasswordReset(email: email);
  }
}
