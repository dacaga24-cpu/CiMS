import 'package:flutter/foundation.dart';

// Aquest enum representa les seccions principals accessibles des del menú inferior.
enum MainBottomNavigationTab {
  map,
  catalog,
  dashboard,
  stats,
}

// Aquest controller gestiona únicament quina secció està activa dins
// de la navegació principal de l’aplicació.
class MainNavigationController extends ChangeNotifier {
  MainBottomNavigationTab _selectedTab = MainBottomNavigationTab.dashboard;

  MainBottomNavigationTab get selectedTab => _selectedTab;

  void onTabSelected(MainBottomNavigationTab tab) {
    if (_selectedTab == tab) return;

    _selectedTab = tab;
    notifyListeners();
  }
}