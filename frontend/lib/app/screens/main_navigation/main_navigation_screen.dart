import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/screens/main_navigation/main_navigation_controller.dart';
import 'package:cims/app/screens/main_navigation/widgets/main_bottom_navigation_bar.dart';
import 'package:cims/app/screens/main_navigation/widgets/main_navigation_header.dart';
import 'package:flutter/material.dart';

@RoutePage()
class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: MainNavigationHeader(
                    onProfileTap: () {
                      context.router.push(const ProfileSettingsRoute());
                    },
                  ),
                ),
                Expanded(
                  child: child,
                ),
              ],
            ),
          ),
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