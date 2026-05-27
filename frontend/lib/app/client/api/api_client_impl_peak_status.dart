part of 'api_client_impl.dart';

// Aquest mixin implementa les peticions relacionades amb l’estat personal dels cims.
// Permet consultar i modificar les marques manuals de l’usuari autenticat.
mixin _PeakStatusApiClientImplMixin on _ApiClientBase
    implements PeakStatusApiClient {
  // Aquest mètode carrega tots els estats de cims de l’usuari.
  // Permet mostrar al catàleg i al perfil quins cims estan completats, marcats com a objectiu o preferits.
  @override
  Future<List<PeakStatus>> getUserPeakStatuses() async {
    final response = await _getJson(
      ApiEndpoints.peakStatus,
      requiresAuth: true,
    );

    if (response.statusCode == 200) {
      final rawList = _tryParseJsonList(response.body);

      if (rawList != null) {
        return rawList
            .whereType<Map<String, dynamic>>()
            .map(PeakStatus.fromJson)
            .toList();
      }

      final data = _tryParseJson(response.body);
      final rawStatuses = _extractStatusList(data);
      return rawStatuses.map(PeakStatus.fromJson).toList();
    }

    throw ApiException(
      'No s\'han pogut carregar els estats dels cims',
      statusCode: response.statusCode,
    );
  }

  // Aquest mètode consulta l’estat personal d’un cim concret.
  // Si no existeix cap registre, retorna un estat buit perquè la interfície pugui treballar amb valors inicials.
  @override
  Future<PeakStatus> getPeakStatus(int peakId) async {
    final response = await _getJson(
      ApiEndpoints.peakStatusByPeakId(peakId),
      requiresAuth: true,
    );

    final data = _tryParseJson(response.body);

    if (response.statusCode == 200) {
      final statusJson = _extractStatus(data);
      return PeakStatus.fromJson(statusJson);
    }

    if (response.statusCode == 404) {
      return PeakStatus.emptyForPeak(peakId);
    }

    throw ApiException(
      'No s\'ha pogut carregar l\'estat del cim',
      statusCode: response.statusCode,
    );
  }

  // Aquest mètode actualitza els estats manuals d’un cim concret.
  // El completat no s’envia perquè el backend el calcula a partir de les ascensions.
  @override
  Future<PeakStatus> updatePeakStatus({
    required int peakId,
    bool? isTarget,
    bool? isFavorite,
  }) async {
    final body = <String, dynamic>{};

    if (isTarget != null) {
      body['isTarget'] = isTarget;
    }

    if (isFavorite != null) {
      body['isFavorite'] = isFavorite;
    }

    final response = await _putJson(
      ApiEndpoints.peakStatusByPeakId(peakId),
      body: body,
      requiresAuth: true,
    );

    final data = _tryParseJson(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final statusJson = _extractStatus(data);
      return PeakStatus.fromJson(statusJson);
    }

    throw ApiException(
      'No s\'ha pogut actualitzar l\'estat del cim',
      statusCode: response.statusCode,
    );
  }

  // Aquest mètode extreu una llista d’estats de la resposta del backend.
  // Accepta els formats previstos i genera un error si la resposta no és vàlida.
  List<Map<String, dynamic>> _extractStatusList(dynamic data) {
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }

    if (data is Map<String, dynamic>) {
      final possibleList = data['statuses'] ?? data['data'];

      if (possibleList is List) {
        return possibleList.whereType<Map<String, dynamic>>().toList();
      }
    }

    throw const ApiException(
      'Resposta inesperada del servidor: format invàlid de la llista d\'estats',
    );
  }

  // Aquest mètode extreu un estat concret de la resposta del backend.
  // Permet adaptar diferents formats de resposta a l’entitat que consumeix l’aplicació.
  Map<String, dynamic> _extractStatus(dynamic data) {
    if (data is Map<String, dynamic>) {
      final possibleStatus =
          data['status'] ?? data['peakStatus'] ?? data['data'];

      if (possibleStatus is Map<String, dynamic>) {
        return possibleStatus;
      }

      return data;
    }

    throw const ApiException(
      'Resposta inesperada del servidor: format invàlid de l\'estat del cim',
    );
  }
}
