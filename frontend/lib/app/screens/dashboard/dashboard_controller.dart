import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/dashboard_summary.dart';
import 'package:cims/core/usecase/get_dashboard_summary_usecase.dart';
import 'package:flutter/material.dart';

// Aquest enum defineix les navegacions possibles des del dashboard.
// La pantalla el consumeix per executar la navegació real sense acoblar el controller a AutoRoute.
enum DashboardDestination {
  none,
  peakDetail,
  stats,
}

// Aquest controller gestiona l’estat funcional del dashboard.
// S’encarrega de carregar el resum de progrés, controlar errors i preparar accions de navegació.
class DashboardController extends ChangeNotifier {
  DashboardController({
    GetDashboardSummaryUseCase? getDashboardSummaryUseCase,
  }) : _getDashboardSummaryUseCase =
           getDashboardSummaryUseCase ?? GetDashboardSummaryUseCase(ApiClientImpl());

  // Aquest cas d’ús centralitza l’obtenció de les dades del dashboard.
  // Permet que el controller no depengui directament de l’origen de les dades.
  final GetDashboardSummaryUseCase _getDashboardSummaryUseCase;

  // Aquest bloc guarda l’estat intern que necessita la pantalla per representar el dashboard.
  // Inclou la càrrega, els errors, les dades rebudes i la navegació pendent.
  bool _isLoading = false;
  String? _errorMessage;
  DashboardSummary? _summary;
  DashboardDestination _destination = DashboardDestination.none;
  int? _selectedPeakId;

  // Aquests getters exposen l’estat del dashboard de manera controlada.
  // La pantalla els consulta per decidir què mostrar i quina navegació executar.
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DashboardSummary? get summary => _summary;
  DashboardDestination get destination => _destination;
  int? get selectedPeakId => _selectedPeakId;

  // Aquest mètode carrega les dades principals del dashboard.
  // Actualitza els estats visuals perquè la pantalla pugui mostrar càrrega, error o contingut.
  Future<void> loadDashboard() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _summary = await _getDashboardSummaryUseCase.execute();
    } on ApiUnauthorizedException {
      _errorMessage = 'La sessió ha caducat. Torna a iniciar sessió.';
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No s\'ha pogut carregar el resum del dashboard.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Aquest mètode prepara la navegació cap al detall d’un cim seleccionat.
  // La pantalla farà la navegació real i després consumirà aquesta destinació.
  void openPeakDetail(int peakId) {
    _selectedPeakId = peakId;
    _destination = DashboardDestination.peakDetail;
    notifyListeners();
  }

  // Aquest mètode prepara la navegació cap a la pantalla d’estadístiques.
  // Permet que el dashboard actuï com a resum i delegui el detall analític a una altra pantalla.
  void openStats() {
    _destination = DashboardDestination.stats;
    notifyListeners();
  }

  // Aquest mètode neteja la navegació pendent després que la pantalla ja l’hagi executat.
  // Evita que la mateixa acció es repeteixi en reconstruccions posteriors.
  void consumeNavigation() {
    _destination = DashboardDestination.none;
    _selectedPeakId = null;
  }

  // Aquest mètode permet reintentar la càrrega quan hi ha hagut un error.
  Future<void> retry() async {
    await loadDashboard();
  }
}