import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/screens/main_navigation/main_bottom_navigation_tab.dart';
import 'package:cims/app/screens/main_navigation/main_navigation_controller.dart';
import 'package:cims/app/screens/main_navigation/widgets/main_bottom_navigation_bar.dart';
import 'package:cims/app/screens/main_navigation/widgets/main_navigation_header.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:flutter/material.dart';

// Aquesta pantalla actua com a contenidor principal de la navegació interna.
// Manté visibles els elements compartits, com la capçalera i el menú inferior,
// mentre AutoRoute carrega la secció activa seleccionada per l’usuari.
@RoutePage()
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late final MainNavigationController controller;

  @override
  void initState() {
    super.initState();

    controller = MainNavigationController();
    controller.loadUserProfileIfNeeded();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // Aquest mètode construeix l’estructura base comuna de les pantalles
  // accessibles des del menú inferior. També connecta el tab bar amb
  // les rutes internes perquè el canvi de secció quedi centralitzat aquí.
  @override
  Widget build(BuildContext context) {
    return AutoTabsRouter(
      // Aquest bloc defineix les seccions principals que formen part
      // de la navegació interna de l’usuari autenticat.
      routes: [
        PeaksMapRoute(),
        const PeaksCatalogRoute(),
        const DashboardRoute(),
        const UserStatsRoute(),
      ],
      builder: (context, child) {
        // Aquest objecte permet consultar i canviar la pestanya activa
        // de manera coordinada amb el menú inferior.
        final tabsRouter = AutoTabsRouter.of(context);

        return Scaffold(
          backgroundColor: const Color(0xFFF4F4F6),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Aquest bloc mostra la capçalera comuna de la navegació principal.
                // Escolta el perfil compartit perquè la foto s’actualitzi quan canviï.
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: AnimatedBuilder(
                    animation: AppSession.userProfileStore,
                    builder: (context, _) {
                      return MainNavigationHeader(
                        profilePhotoUrl:
                            AppSession.userProfileStore.profilePhotoUrl,
                        onProfileTap: () {
                          context.router.root.push(ProfileSettingsRoute());
                        },
                      );
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