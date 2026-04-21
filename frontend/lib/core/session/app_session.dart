import 'package:cims/core/client/session_storage.dart';
import 'package:cims/app/client/session/session_storage_impl.dart';
import 'package:cims/core/usecase/session/clear_session_usecase.dart';
import 'package:cims/core/usecase/session/has_saved_session_usecase.dart';
import 'package:cims/core/usecase/session/save_session_usecase.dart';

// Aquest punt centralitza tota la gestió de sessió del frontend.
// Manté una única instància de persistència i exposa els casos d’ús
// que necessiten diferents pantalles o serveis de l’aplicació.
class AppSession {
  AppSession._();

  // Aquest bloc manté els elements compartits relacionats amb la sessió.
  // Això permet reutilitzar la mateixa base de persistència i els mateixos casos d’ús
  // a qualsevol punt de l’aplicació.
  static late final SessionStorage storage;
  static late final HasSavedSessionUseCase hasSavedSessionUseCase;
  static late final SaveSessionUseCase saveSessionUseCase;
  static late final ClearSessionUseCase clearSessionUseCase;

  // Aquest callback guarda l’acció global que s’executarà
  // quan la sessió deixi de ser vàlida.
  static Future<void> Function()? _onSessionExpired;

  // Aquest mètode inicialitza la infraestructura comuna de sessió.
  // Crea la persistència real i prepara els casos d’ús necessaris
  // per guardar, comprovar o netejar la sessió de l’usuari.
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
  }

  // Aquest callback permet decidir des de fora què ha de passar
  // quan el backend indica que la sessió ja no és vàlida.
  static void setOnSessionExpired(Future<void> Function() callback) {
    _onSessionExpired = callback;
  }

  // Aquest mètode centralitza la reacció davant d’una sessió caducada:
  // neteja la sessió local i executa la redirecció global a login.
  static Future<void> handleUnauthorized() async {
    await clearSessionUseCase.execute();

    if (_onSessionExpired != null) {
      await _onSessionExpired!();
    }
  }
}