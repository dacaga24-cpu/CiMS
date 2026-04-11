import 'package:auto_route/auto_route.dart';
import 'package:cims/app/screens/app_start/app_start_screen.dart';
import 'package:cims/app/screens/login/login_screen.dart';
import 'package:cims/app/screens/dashboard/dashboard_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: AppStartRoute.page, initial: true),
        AutoRoute(page: LoginRoute.page),
        AutoRoute(page: DashboardRoute.page),
      ];
}