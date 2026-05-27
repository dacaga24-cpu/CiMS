import 'package:cims/app/client/session/session_storage_impl.dart';
import 'package:cims/app/screens/peaks_catalog/models/peaks_filter_state.dart';
import 'package:cims/core/client/session_storage.dart';
import 'package:cims/core/store/peak_status_store.dart';
import 'package:cims/core/store/user_profile_store.dart';
import 'package:cims/core/store/user_stats_refresh_store.dart';
import 'package:cims/core/usecase/session/clear_session_usecase.dart';
import 'package:cims/core/usecase/session/has_saved_session_usecase.dart';
import 'package:cims/core/usecase/session/save_session_usecase.dart';

// Aquest punt centralitza la gestió de sessió del frontend.
// Manté la persistència, els casos d’ús i els stores compartits de l’usuari autenticat.
class AppSession {
  AppSession._();

  // Aquest bloc agrupa els recursos principals de sessió.
  // Permet reutilitzar la mateixa persistència i els mateixos casos d’ús a tota l’aplicació.
  static late final SessionStorage storage;
  static late final HasSavedSessionUseCase hasSavedSessionUseCase;
  static late final SaveSessionUseCase saveSessionUseCase;
  static late final ClearSessionUseCase clearSessionUseCase;

  // Aquest store notifica canvis que afecten la pantalla d’estadístiques.
  // Permet recarregar les dades quan es registra una nova ascensió.
  static late final UserStatsRefreshStore userStatsRefreshStore;

  // Aquest store manté els estats personals dels cims durant la sessió.
  // Es buida en tancar sessió per evitar mostrar dades d’un usuari anterior.
  static late final PeakStatusStore peakStatusStore;

  // Aquest store manté les dades bàsiques del perfil de l’usuari autenticat.
  // Permet reutilitzar la foto de perfil a diferents parts de la interfície.
  static late final UserProfileStore userProfileStore;

  // Aquest callback guarda l’acció global que s’executarà quan la sessió deixi de ser vàlida.
  static Future<void> Function()? _onSessionExpired;

  // Aquest mètode inicialitza la infraestructura comuna de sessió.
  // Crea la persistència, prepara els casos d’ús i inicialitza els stores compartits.
  static void initialize({
    SessionStorage? sessionStorage,
  }) {
    storage = sessionStorage ?? SessionStorageImpl();

    hasSavedSessionUseCase = HasSavedSessionUseCase(
      sessionStorage: storage,
    );

    saveSessionUseCase = SaveSessionUseCase(
      sessionStorage: storage,
    );

    clearSessionUseCase = ClearSessionUseCase(
      sessionStorage: storage,
    );

    userStatsRefreshStore = UserStatsRefreshStore();
    peakStatusStore = PeakStatusStore();
    userProfileStore = UserProfileStore();
  }

  // Aquest callback permet definir què passa quan el backend indica que la sessió ja no és vàlida.
  static void setOnSessionExpired(Future<void> Function() callback) {
    _onSessionExpired = callback;
  }

  // Aquest mètode centralitza la reacció davant d’una sessió caducada.
  // Neteja la sessió local, buida l’estat compartit i executa la redirecció global.
  static Future<void> handleUnauthorized() async {
    await clearSessionUseCase.execute();
    peakStatusStore.clear();
    userProfileStore.clear();
    PeaksFilterState.shared.clear();

    if (_onSessionExpired != null) {
      await _onSessionExpired!();
    }
  }
}