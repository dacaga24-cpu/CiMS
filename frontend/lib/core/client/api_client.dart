class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

abstract class ApiClient {
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });
}