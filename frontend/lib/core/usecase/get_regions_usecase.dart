import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/region.dart';

// Aquest cas d’ús encapsula la càrrega de comarques disponibles des del backend.
// Serveix per separar aquesta acció de negoci de la capa visual i mantenir
// els controllers centrats només en l’estat i el comportament de la pantalla.
class GetRegionsUseCase {
  const GetRegionsUseCase({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  // Aquest client és el punt de comunicació amb el backend
  // per recuperar les comarques del sistema.
  final ApiClient _apiClient;

  // Aquest mètode executa la consulta de comarques i retorna
  // la llista preparada perquè el controller o la pantalla la puguin utilitzar.
  Future<List<Region>> execute() {
    return _apiClient.getRegions();
  }
}