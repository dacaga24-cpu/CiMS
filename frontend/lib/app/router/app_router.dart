import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/guards/auth_guard.dart';
import 'package:cims/app/screens/app_start/app_start_screen.dart';
import 'package:cims/app/screens/ascent_edit/ascent_edit_screen.dart';
import 'package:cims/app/screens/ascent_history/ascent_history_screen.dart';
import 'package:cims/app/screens/ascent_register/ascent_register_screen.dart';
import 'package:cims/app/screens/ascent_verification/ascent_verification_screen.dart';
import 'package:cims/app/screens/dashboard/dashboard_screen.dart';
import 'package:cims/app/screens/login/login_screen.dart';
import 'package:cims/app/screens/main_navigation/main_navigation_screen.dart';
import 'package:cims/app/screens/peak_detail/peak_detail_screen.dart';
import 'package:cims/app/screens/peaks_catalog/peaks_catalog_screen.dart';
import 'package:cims/app/screens/peaks_map/peaks_map_screen.dart';
import 'package:cims/app/screens/profile_settings/profile_settings_screen.dart';
import 'package:cims/app/screens/register/register_screen.dart';
import 'package:cims/app/screens/reset_password/reset_password_screen.dart';
import 'package:cims/app/screens/user_photo_gallery/user_photo_gallery_screen.dart';
import 'package:cims/app/screens/user_stats/user_stats_screen.dart';
import 'package:cims/core/entity/ascent.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

part 'app_router.gr.dart';

// Aquesta classe defineix l’organització de navegació principal de l’aplicació.
// Aquí s’indica quines pantalles existeixen i com s’estructura el flux general de CiMS.
@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  AppRouter({
    required this.authGuard,
  });

  // Aquest guard controla l’accés a les zones protegides de l’aplicació
  // i evita que s’hi entri sense una sessió vàlida.
  final AuthGuard authGuard;

  // Aquest bloc recull les rutes principals de l’aplicació.
  // Les pantalles d’autenticació viuen al primer nivell i la navegació interna
  // de l’usuari autenticat queda agrupada dins de MainNavigationRoute.
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: AppStartRoute.page, initial: true),
        AutoRoute(page: LoginRoute.page, path: '/login'),
        AutoRoute(page: RegisterRoute.page, path: '/register'),
        AutoRoute(
          page: ResetPasswordRoute.page,
          path: '/reset-password',
        ),
        AutoRoute(
          page: PeakDetailRoute.page,
          path: '/peaks/:peakId',
          guards: [authGuard],
        ),
        AutoRoute(
          page: AscentRegisterRoute.page,
          path: '/ascents/register',
          guards: [authGuard],
        ),
        AutoRoute(
          page: AscentVerificationRoute.page,
          path: '/ascents/verify',
          guards: [authGuard],
        ),
        AutoRoute(
          page: AscentHistoryRoute.page,
          path: '/ascents/history',
          guards: [authGuard],
        ),
        AutoRoute(
          page: AscentEditRoute.page,
          path: '/ascents/edit',
          guards: [authGuard],
        ),
        AutoRoute(
          page: UserPhotoGalleryRoute.page,
          path: '/photo-gallery',
          guards: [authGuard],
        ),
        AutoRoute(
          page: MainNavigationRoute.page,
          path: '/main',
          guards: [authGuard],
          children: [
            AutoRoute(page: DashboardRoute.page, path: '', initial: true),
            AutoRoute(page: PeaksMapRoute.page, path: 'map'),
            AutoRoute(page: PeaksCatalogRoute.page, path: 'catalog'),
            AutoRoute(page: UserStatsRoute.page, path: 'stats'),
          ],
        ),
        AutoRoute(
          page: ProfileSettingsRoute.page,
          path: '/profile-settings',
          guards: [authGuard],
        ),
      ];
}
