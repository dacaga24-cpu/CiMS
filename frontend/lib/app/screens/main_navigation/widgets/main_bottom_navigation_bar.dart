import 'package:cims/app/screens/main_navigation/main_bottom_navigation_tab.dart';
import 'package:flutter/material.dart';

// Aquest widget encapsula el menú inferior principal de l’aplicació.
// Manté el mateix estil visual i evita que la configuració del tab bar
// quedi barrejada amb el layout general de la navegació principal.
class MainBottomNavigationBar extends StatelessWidget {
  const MainBottomNavigationBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final MainBottomNavigationTab selectedTab;
  final ValueChanged<MainBottomNavigationTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavigationItem(
                icon: Icons.grid_view_rounded,
                label: 'INICI',
                isSelected: selectedTab == MainBottomNavigationTab.dashboard,
                onTap: () => onTabSelected(MainBottomNavigationTab.dashboard),
              ),
              _NavigationItem(
                icon: Icons.map_outlined,
                label: 'MAPA',
                isSelected: selectedTab == MainBottomNavigationTab.map,
                onTap: () => onTabSelected(MainBottomNavigationTab.map),
              ),
              _NavigationItem(
                icon: Icons.format_list_bulleted_rounded,
                label: 'LLISTAT',
                isSelected: selectedTab == MainBottomNavigationTab.catalog,
                onTap: () => onTabSelected(MainBottomNavigationTab.catalog),
              ),
              _NavigationItem(
                icon: Icons.bar_chart_rounded,
                label: 'DADES',
                isSelected: selectedTab == MainBottomNavigationTab.stats,
                onTap: () => onTabSelected(MainBottomNavigationTab.stats),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Aquest element intern representa cadascuna de les opcions del menú inferior.
// Rep només la informació estrictament necessària perquè continuï sent un widget visual.
class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        isSelected ? const Color(0xFF0B57D0) : const Color(0xFF9AA3B2);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: activeColor,
                ),
                const SizedBox(height: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: activeColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}