import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/screens/main_navigation/main_navigation_controller.dart';
import 'package:cims/app/screens/main_navigation/widgets/main_bottom_navigation_bar.dart';
import 'package:cims/app/screens/main_navigation/widgets/main_navigation_header.dart';
import 'package:flutter/material.dart';

// Aquesta pantalla actua com a contenidor principal de la navegació interna.
// Manté visibles els elements compartits, com la capçalera i el menú inferior,
// mentre AutoRoute carrega la secció activa seleccionada per l’usuari.
@RoutePage()
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

   // Aquest mètode construeix l’estructura base comuna de les pantalles
  // accessibles des del menú inferior. També connecta el tab bar amb
  // les rutes internes perquè el canvi de secció quedi centralitzat aquí.
  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      routes: const [
        PeaksMapRoute(),
        PeaksCatalogRoute(),
        DashboardRoute(),
        UserStatsRoute(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);

        return Scaffold(
          backgroundColor: const Color(0xFFF4F4F6),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Aquest bloc mostra la capçalera comuna de la navegació principal.
                // Des d’aquí es manté l’accés al perfil/configuració sense duplicar
                // aquest element a cada pantalla interna.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: MainNavigationHeader(
                    onProfileTap: () {
                      context.router.push(const ProfileSettingsRoute());
                    },
                  ),
                ),
                // Aquest espai mostra la ruta interna activa.
                // El contingut canvia segons la pestanya seleccionada al tab bar.                
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
          // Aquest menú inferior es manté sempre visible mentre l’usuari
          // navega per les seccions principals de l’aplicació.
          bottomNavigationBar: MainBottomNavigationBar(
            selectedTab: MainBottomNavigationTab.values[tabsRouter.activeIndex],
            onTabSelected: (tab) {
              tabsRouter.setActiveIndex(tab.index);
            },
          ),
        );
      },
    );
  }
}