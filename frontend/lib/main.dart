import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/router/guards/auth_guard.dart';
import 'package:cims/app/theme/app_theme.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
// La importació condicional selecciona l'stub a builds natius i la versió
// real a web. Cal mantenir-la perquè dart2js no eliminava el registre del
// plugin web del geolocator i la captura d'ubicació petava amb
// MissingPluginException (vegeu el comentari del fitxer web).
import 'package:cims/core/platform/web_plugins_register.dart'
    if (dart.library.js_interop)
        'package:cims/core/platform/web_plugins_register_web.dart';

// Aquest mètode prepara la sessió compartida, crea el router principal
// i configura la redirecció global quan una sessió caduqui.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Garanteix que els plugins web s'han registrat abans d'iniciar l'app.
  // En builds natius és un no-op; a web força el registre del geolocator.
  ensureWebPluginsRegistered();

  // Aquest ajust elimina el símbol # de les URLs a web
  // per fer la navegació més neta i més propera a una web convencional.
  usePathUrlStrategy();

  // Inicialitza els recursos compartits relacionats amb la sessió
  // abans d’arrencar l’aplicació.
  AppSession.initialize();

  // Crea el router principal i hi associa el guard d’autenticació
  // perquè l’aplicació pugui controlar l’accés a les pantalles protegides.
  final appRouter = AppRouter(
    authGuard: AuthGuard(
      hasSavedSessionUseCase: AppSession.hasSavedSessionUseCase,
      // Defineix què ha de passar quan un usuari intenta accedir
      // a una zona protegida sense tenir una sessió vàlida.
      redirectToLogin: (router) {
        router.replaceAll([
          const LoginRoute(),
        ]);
      },
    ),
  );

  // Registra l’acció global que es farà quan la sessió caduqui,
  // forçant el retorn a la pantalla de login.
  AppSession.setOnSessionExpired(() async {
    appRouter.replaceAll([
      const LoginRoute(),
    ]);
  });

  // Inicia l’aplicació passant-li el router ja configurat.
  runApp(MyApp(appRouter: appRouter));
}

// Aquest widget representa la base de l’aplicació.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.appRouter,
  });

  // Guarda el router principal que controla la navegació global
  // de tota l’aplicació.
  final AppRouter appRouter;

  @override
  Widget build(BuildContext context) {
    // Construeix l’aplicació principal utilitzant navegació declarativa
    // basada en router.
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter.config(),
      theme: AppTheme.light,
    );
  }
}