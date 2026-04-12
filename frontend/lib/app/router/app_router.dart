import 'package:auto_route/auto_route.dart';
import 'package:cims/app/screens/app_start/app_start_screen.dart';
import 'package:cims/app/screens/login/login_screen.dart';
import 'package:cims/app/screens/dashboard/dashboard_screen.dart';

part 'app_router.gr.dart';

// Aquesta classe defineix l’organització de navegació principal de l’aplicació
// Aquí s’indica quines pantalles existeixen i en quin ordre es poden carregar.
@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {

 // Aquest bloc recull les rutes principals de l’aplicació.
  // També estableix quina és la pantalla inicial que es mostra quan l’usuari obre CiMS.
  @override  
  List<AutoRoute> get routes => [
        AutoRoute(page: AppStartRoute.page, initial: true),
        AutoRoute(page: LoginRoute.page),
        AutoRoute(page: DashboardRoute.page),
      ];
}