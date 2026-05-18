import 'package:cims/app/screens/main_navigation/main_bottom_navigation_tab.dart';
import 'package:cims/app/widgets/branding/cims_logo.dart';
import 'package:cims/app/widgets/profile/profile_avatar.dart';
import 'package:flutter/material.dart';

class MainNavigationRail extends StatelessWidget {
  const MainNavigationRail({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.onVerificationTap,
    required this.onProfileTap,
    required this.extended,
    this.profilePhotoUrl,
  });

  final MainBottomNavigationTab selectedTab;
  final ValueChanged<MainBottomNavigationTab> onTabSelected;
  final VoidCallback onVerificationTap;
  final VoidCallback onProfileTap;
  final bool extended;
  final String? profilePhotoUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: extended ? 236 : 76,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            right: BorderSide(
              color: Color(0xFFE5E7EB),
            ),
          ),
        ),
        child: SafeArea(
          bottom: true,
          child: Column(
            children: [
              Expanded(
                child: NavigationRail(
                  backgroundColor: Colors.white,
                  selectedIndex: selectedTab.index,
                  extended: extended,
                  labelType: extended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.selected,
                  minWidth: 76,
                  minExtendedWidth: 236,
                  groupAlignment: -1,
                  selectedIconTheme: const IconThemeData(
                    color: Color(0xFF0B57D0),
                    size: 25,
                  ),
                  unselectedIconTheme: const IconThemeData(
                    color: Color(0xFF7B8494),
                    size: 24,
                  ),
                  selectedLabelTextStyle: const TextStyle(
                    color: Color(0xFF0B57D0),
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: Color(0xFF596274),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  indicatorColor: const Color(0xFFE8F0FE),
                  onDestinationSelected: (index) {
                    onTabSelected(MainBottomNavigationTab.values[index]);
                  },
                  leading: Padding(
                    padding: EdgeInsets.fromLTRB(
                      extended ? 20 : 12,
                      16,
                      extended ? 20 : 12,
                      8,
                    ),
                    child: Column(
                      children: [
                        _RailBrand(extended: extended),
                        const SizedBox(height: 18),
                        _RailDivider(extended: extended),
                      ],
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.grid_view_rounded),
                      selectedIcon: Icon(Icons.grid_view_rounded),
                      label: Text('Inici'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.map_outlined),
                      selectedIcon: Icon(Icons.map_rounded),
                      label: Text('Mapa'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.format_list_bulleted_rounded),
                      selectedIcon: Icon(Icons.format_list_bulleted_rounded),
                      label: Text('Llistat'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bar_chart_rounded),
                      selectedIcon: Icon(Icons.bar_chart_rounded),
                      label: Text('Dades'),
                    ),
                  ],
                  trailing: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        _RailDivider(extended: extended),
                        if (!extended) ...[
                          const SizedBox(height: 16),
                          _RailVerificationButton(
                            onTap: onVerificationTap,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  extended ? 12 : 0,
                  0,
                  extended ? 12 : 0,
                  16,
                ),
                child: _RailProfileButton(
                  extended: extended,
                  profilePhotoUrl: profilePhotoUrl,
                  onTap: onProfileTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailBrand extends StatelessWidget {
  const _RailBrand({
    required this.extended,
  });

  final bool extended;

  @override
  Widget build(BuildContext context) {
    if (!extended) {
      return const Tooltip(
        message: 'CiMS',
        child: CimsLogo(
          width: 46,
          height: 46,
        ),
      );
    }

    return const CimsLogo(
      width: 72,
      height: 72,
    );
  }
}

class _RailVerificationButton extends StatelessWidget {
  const _RailVerificationButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Verificar ascensio',
      child: IconButton.filled(
        onPressed: onTap,
        icon: const Icon(Icons.photo_camera_rounded),
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFF0B57D0),
          foregroundColor: Colors.white,
          fixedSize: const Size(52, 52),
        ),
      ),
    );
  }
}

class _RailDivider extends StatelessWidget {
  const _RailDivider({
    required this.extended,
  });

  final bool extended;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: extended ? 196 : 44,
      child: const Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFE5E7EB),
      ),
    );
  }
}

class _RailProfileButton extends StatelessWidget {
  const _RailProfileButton({
    required this.extended,
    required this.onTap,
    this.profilePhotoUrl,
  });

  final bool extended;
  final VoidCallback onTap;
  final String? profilePhotoUrl;

  @override
  Widget build(BuildContext context) {
    if (!extended) {
      return Tooltip(
        message: 'Perfil',
        child: ProfileAvatar(
          size: 42,
          profilePhotoUrl: profilePhotoUrl,
          onTap: onTap,
          backgroundColor: const Color(0xFF0B57D0),
          iconColor: Colors.white,
          iconSize: 22,
        ),
      );
    }

    return Material(
      color: const Color(0xFFF6F8FB),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ProfileAvatar(
                size: 40,
                profilePhotoUrl: profilePhotoUrl,
                backgroundColor: const Color(0xFF0B57D0),
                iconColor: Colors.white,
                iconSize: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Perfil',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF17212B),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF7B8494),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
