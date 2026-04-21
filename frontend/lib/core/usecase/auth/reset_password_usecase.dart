import 'package:cims/core/client/api_client.dart';

class ResetPasswordUseCase {
  const ResetPasswordUseCase({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<void> execute({
    required String token,
    required String newPassword,
  }) {
    return _apiClient.resetPassword(
      token: token,
      newPassword: newPassword,
    );
  }
}
