import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/dashboard_summary.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/store/user_stats_refresh_store.dart';
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
    UserStatsRefreshStore? userStatsRefreshStore,
  })  : _getDashboardSummaryUseCase = getDashboardSummaryUseCase ??
            GetDashboardSummaryUseCase(ApiClientImpl()),
        _userStatsRefreshStore =
            userStatsRefreshStore ?? AppSession.userStatsRefreshStore {
    _userStatsRefreshStore.addListener(_handleDashboardChanged);
  }

  // Aquest cas d’ús centralitza l’obtenció de les dades del dashboard.
  // Permet que el controller no depengui directament de l’origen de les dades.
  final GetDashboardSummaryUseCase _getDashboardSummaryUseCase;

  // Aquest store permet detectar canvis fets en altres pantalles.
  // Quan l’usuari modifica l’estat d’un cim, el dashboard es pot actualitzar automàticament.
  final UserStatsRefreshStore _userStatsRefreshStore;

  // Aquest bloc guarda l’estat intern que necessita la pantalla per representar el dashboard.
  // Inclou la càrrega, els errors, les dades rebudes i la navegació pendent.
  bool _isLoading = false;
  bool _disposed = false;
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

  // Aquest mètode respon als canvis globals d’estadístiques o estats de cims.
  // Permet refrescar el dashboard sense obligar l’usuari a actualitzar manualment.
  void _handleDashboardChanged() {
    if (_disposed) return;

    loadDashboard();
  }

  // Aquest mètode carrega les dades principals del dashboard.
  // Actualitza els estats visuals perquè la pantalla pugui mostrar càrrega, error o contingut.
  Future<void> loadDashboard() async {
    if (_isLoading || _disposed) return;

    _isLoading = true;
    _errorMessage = null;
    _notifyIfActive();

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
      _notifyIfActive();
    }
  }

  // Aquest mètode prepara la navegació cap al detall d’un cim seleccionat.
  // La pantalla farà la navegació real i després consumirà aquesta destinació.
  void openPeakDetail(int peakId) {
    if (_disposed) return;

    _selectedPeakId = peakId;
    _destination = DashboardDestination.peakDetail;
    _notifyIfActive();
  }

  // Aquest mètode prepara la navegació cap a la pantalla d’estadístiques.
  // Permet que el dashboard actuï com a resum i delegui el detall analític a una altra pantalla.
  void openStats() {
    if (_disposed) return;

    _destination = DashboardDestination.stats;
    _notifyIfActive();
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

  // Aquest mètode centralitza la notificació segura a la pantalla.
  // Evita avisar listeners quan el controller ja ha estat alliberat.
  void _notifyIfActive() {
    if (_disposed) return;

    notifyListeners();
  }

  // Aquest mètode elimina l’escolta del store global quan el dashboard es destrueix.
  // Evita que el controller continuï rebent avisos quan la pantalla ja no existeix.
  @override
  void dispose() {
    _disposed = true;
    _userStatsRefreshStore.removeListener(_handleDashboardChanged);
    super.dispose();
  }
}
