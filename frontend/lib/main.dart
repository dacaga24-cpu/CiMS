import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/router/guards/auth_guard.dart';
import 'package:cims/app/theme/app_theme.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// Aquesta importació selecciona el registre de plugins adequat per a cada plataforma.
// A web permet preparar els plugins necessaris abans que l’aplicació comenci a executar-se.
import 'package:cims/core/platform/web_plugins_register.dart'
    if (dart.library.js_interop) 'package:cims/core/platform/web_plugins_register_web.dart';

// Aquest mètode inicialitza la configuració global de l’aplicació.
// Prepara la sessió, el registre de plugins, el router i la redirecció quan la sessió caduca.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Aquest pas garanteix que els plugins web necessaris estiguin registrats.
  // En plataformes natives no fa cap acció perquè Flutter ja gestiona aquest registre.
  ensureWebPluginsRegistered();

  // Aquest ajust elimina el símbol # de les URLs en la versió web.
  // Fa que les rutes siguin més netes i més adequades per a una aplicació desplegada.
  usePathUrlStrategy();

  // Aquest pas inicialitza els recursos compartits de sessió.
  // Ha d’executar-se abans de crear pantalles o serveis que depenguin de l’usuari autenticat.
  AppSession.initialize();

  // Aquest router centralitza la navegació principal de l’aplicació.
  // El guard d’autenticació controla l’accés a les pantalles protegides.
  final appRouter = AppRouter(
    authGuard: AuthGuard(
      hasSavedSessionUseCase: AppSession.hasSavedSessionUseCase,
      // Aquesta acció redirigeix al login quan l’usuari no té una sessió vàlida.
      redirectToLogin: (router) {
        router.replaceAll([
          const LoginRoute(),
        ]);
      },
    ),
  );

  // Aquest callback defineix la resposta global davant d’una sessió caducada.
  // Quan el backend rebutja el token, l’aplicació torna al login de manera centralitzada.
  AppSession.setOnSessionExpired(() async {
    appRouter.replaceAll([
      const LoginRoute(),
    ]);
  });

  // Aquest punt arrenca l’aplicació amb el router ja configurat.
  runApp(MyApp(appRouter: appRouter));
}

// Aquest widget representa l’arrel visual de l’aplicació.
// Defineix el tema, la navegació i la localització general.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.appRouter,
  });

  // Aquest router controla totes les rutes principals de l’aplicació.
  final AppRouter appRouter;

  @override
  Widget build(BuildContext context) {
    // Aquesta configuració construeix l’aplicació amb navegació declarativa.
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter.config(),
      theme: AppTheme.light,
      // Aquesta configuració fixa el català com a idioma principal dels widgets del sistema.
      // Manté coherents elements com selectors de data, textos interns i components natius.
      locale: const Locale('ca'),
      supportedLocales: const [Locale('ca')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}