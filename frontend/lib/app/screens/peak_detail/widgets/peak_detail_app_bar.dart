import 'package:flutter/material.dart';

// Aquesta barra superior manté l’estil net del detall del cim.
// Es defineix com a widget propi perquè la pantalla principal no hagi de construir UI auxiliar.
class PeakDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PeakDetailAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    );
  }
}
