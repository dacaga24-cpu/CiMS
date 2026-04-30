// lib/core/usecase/get_ascents_by_peak_usecase.dart

import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/ascent.dart';

// Aquest cas d’ús recupera les ascensions de l’usuari autenticat
// associades a un cim concret.
class GetAscentsByPeakUseCase {
  const GetAscentsByPeakUseCase(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Ascent>> call(int peakId) {
    return _apiClient.getAscentsByPeak(peakId);
  }
}