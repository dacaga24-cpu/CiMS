import 'package:auto_route/auto_route.dart';
import 'package:cims/core/usecase/session/has_saved_session_usecase.dart';

// Aquest guard evita que un usuari entri a rutes privades si no té sessió guardada.
// No coneix cap ruta concreta per evitar dependències circulars amb el router.
class AuthGuard extends AutoRouteGuard {
  AuthGuard({
    required HasSavedSessionUseCase hasSavedSessionUseCase,
    required void Function(StackRouter router) redirectToLogin,
  })  : _hasSavedSessionUseCase = hasSavedSessionUseCase,
        _redirectToLogin = redirectToLogin;

  // Aquest use case permet comprovar si l’aplicació conserva una sessió
  // vàlida abans de deixar passar l’usuari a una ruta protegida.
  final HasSavedSessionUseCase _hasSavedSessionUseCase;

  // Aquesta funció encapsula la redirecció cap al login quan l’usuari
  // no pot accedir a una zona privada.
  final void Function(StackRouter router) _redirectToLogin;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    // Abans d’entrar a una ruta protegida, es comprova si hi ha
    // una sessió guardada que permeti mantenir l’accés.
    final hasSession = await _hasSavedSessionUseCase.execute();

    if (hasSession) {
      resolver.next(true);
      return;
    }

    // Si no hi ha sessió disponible, es talla la navegació
    // i es força el retorn de l’usuari a la pantalla de login.
    _redirectToLogin(router);
    resolver.next(false);
  }
}