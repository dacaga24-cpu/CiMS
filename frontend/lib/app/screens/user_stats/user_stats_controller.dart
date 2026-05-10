import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/user_stats.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/store/user_stats_refresh_store.dart';
import 'package:cims/core/usecase/get_user_stats_usecase.dart';
import 'package:flutter/material.dart';

// Aquest controller gestiona l’estat de la pantalla d’estadístiques.
// Carrega les dades reals del backend i prepara la informació perquè la UI
// només hagi de representar càrrega, error o contingut.
class UserStatsController extends ChangeNotifier {
  UserStatsController({
    GetUserStatsUseCase? getUserStatsUseCase,
    UserStatsRefreshStore? userStatsRefreshStore,
  })  : _getUserStatsUseCase =
            getUserStatsUseCase ?? GetUserStatsUseCase(ApiClientImpl()),
        _userStatsRefreshStore =
            userStatsRefreshStore ?? AppSession.userStatsRefreshStore {
    _userStatsRefreshStore.addListener(_handleStatsChanged);
  }

  // Aquest cas d’ús encapsula la consulta de les estadístiques personals.
  // El controller no fa peticions HTTP directes.
  final GetUserStatsUseCase _getUserStatsUseCase;

  // Aquest store permet detectar quan una acció externa, com registrar una ascensió,
  // pot haver modificat les dades que es mostren a estadístiques.
  final UserStatsRefreshStore _userStatsRefreshStore;

  // Aquest bloc conserva les dades rebudes del backend i els estats visuals
  // necessaris per saber si la pantalla ha de mostrar contingut, càrrega o error.
  UserStats? _stats;
  UserStats? get stats => _stats;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Aquestes banderes internes eviten actualitzacions insegures i càrregues repetides.
  // Són importants perquè la pantalla pot reconstruir-se sense haver de repetir la petició inicial.
  bool _disposed = false;
  bool _hasLoaded = false;

  // Aquest getter indica si s’ha de mostrar la càrrega inicial completa.
  // Si ja hi ha dades carregades, es pot refrescar sense buidar la pantalla.
  bool get isInitialLoading => _isLoading && _stats == null;

  // Aquest getter calcula el progrés del repte dels 100 cims.
  // Si el backend no envia cap objecte específic de repte, es calcula
  // a partir dels cims completats.
  int get challengeCurrent {
    final currentStats = _stats;
    if (currentStats == null) return 0;

    return currentStats.challengeProgress?.current ??
        currentStats.completedPeaks;
  }

  // Aquest getter defineix l’objectiu total del repte.
  // Si el backend no envia cap valor específic, es manté el repte per defecte de 100 cims.
  int get challengeTarget {
    final currentStats = _stats;
    if (currentStats == null) return 100;

    return currentStats.challengeProgress?.target ?? 100;
  }

  // Aquest getter calcula el percentatge del repte dins d’un rang segur entre 0 i 100.
  // Prioritza el valor del backend i només fa el càlcul local quan no arriba definit.
  int get challengePercentage {
    final currentStats = _stats;
    if (currentStats == null) return 0;

    final backendPercentage = currentStats.challengeProgress?.percentage;
    if (backendPercentage != null) {
      return backendPercentage.clamp(0, 100);
    }

    if (challengeTarget == 0) return 0;

    return ((challengeCurrent / challengeTarget) * 100).round().clamp(0, 100);
  }

  // Aquest getter genera un text breu de comparativa recent.
  // De moment utilitza l’evolució mensual d’ascensions perquè el backend encara
  // no retorna metres acumulats per mes.
  String get monthlyComparisonLabel {
    final monthlyAscents = _stats?.monthlyAscents ?? const [];

    if (monthlyAscents.length < 2) {
      return 'Dades acumulades del teu historial';
    }

    final previous = monthlyAscents[monthlyAscents.length - 2].total;
    final current = monthlyAscents.last.total;

    if (previous == 0 && current > 0) {
      return '+100% des del mes passat';
    }

    if (previous == 0) {
      return 'Sense variació respecte al mes passat';
    }

    final variation = (((current - previous) / previous) * 100).round();

    if (variation > 0) {
      return '+$variation% des del mes passat';
    }

    if (variation < 0) {
      return '$variation% respecte al mes passat';
    }

    return 'Sense variació respecte al mes passat';
  }

  // Aquest mètode carrega les dades només una vegada quan la pantalla entra en ús.
  Future<void> initialize() async {
    if (_hasLoaded) return;

    _hasLoaded = true;
    await loadStats();
  }

  // Aquest mètode s’executa quan una altra part de l’aplicació indica
  // que les estadístiques poden haver canviat.
  void _handleStatsChanged() {
    loadStats();
  }

  // Aquest mètode demana les estadístiques al backend i actualitza l’estat visual.
  Future<void> loadStats() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      _stats = await _getUserStatsUseCase.execute();
    } on ApiUnauthorizedException {
      // La sessió caducada ja es gestiona de manera centralitzada.
      // Per això no cal mostrar cap error propi en aquesta pantalla.
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No s\'han pogut carregar les estadístiques';
    } finally {
      _isLoading = false;

      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  // Aquest mètode permet refrescar les dades manualment des de la pantalla.
  Future<void> onRefresh() {
    return loadStats();
  }

  // Aquest mètode permet reintentar la càrrega quan hi ha hagut un error.
  Future<void> onRetryTap() {
    return loadStats();
  }

  // Aquest mètode marca el controller com a finalitzat abans d’alliberar-lo.
  // També deixa d’escoltar el store compartit per evitar actualitzacions innecessàries.
  @override
  void dispose() {
    _userStatsRefreshStore.removeListener(_handleStatsChanged);
    _disposed = true;
    super.dispose();
  }
}