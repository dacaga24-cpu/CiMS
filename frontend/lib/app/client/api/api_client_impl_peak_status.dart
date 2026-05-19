part of 'api_client_impl.dart';

// Aquest mixin implementa les peticions relacionades amb l’estat personal dels cims.
// Permet consultar l’estat complet i modificar només els flags manuals,
// com objectiu i preferit, per a l’usuari autenticat.
mixin _PeakStatusApiClientImplMixin on _ApiClientBase
    implements PeakStatusApiClient {
  // Aquest mètode carrega tots els estats de cims associats a l’usuari autenticat.
  // Permet saber quins cims té marcats com a completats, objectius o preferits
  // per mostrar aquesta informació al catàleg i al perfil.
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
  // Si encara no existeix cap registre per aquell cim, retorna un estat buit
  // perquè la interfície pugui treballar igualment amb valors inicials.
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

  // Aquest mètode actualitza només els estats manuals d’un cim concret.
  // El completat no s’envia al backend perquè es calcula a partir de les ascensions.
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

  // Aquest mètode extreu una llista d’estats encara que el backend la retorni
  // directament o embolicada dins d’una propietat com data o statuses.
  // Si la resposta no encaixa amb cap dels formats esperats es llança una
  // ApiException explícita perquè el cridant la pugui tractar com a error de
  // comunicació en lloc de rebre una llista buida que confondria amb "sense
  // estats" i amagaria el problema.
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

  // Aquest mètode extreu un estat concret encara que el backend el retorni
  // directament o dins d’una propietat específica.
  // Es llança una ApiException si la resposta no és un objecte vàlid, perquè
  // el controlador la pugui mostrar amb el mateix tractament que la resta
  // d'errors d'API en lloc d'una FormatException no capturada.
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
