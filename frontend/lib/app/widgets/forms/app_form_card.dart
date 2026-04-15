import 'package:flutter/material.dart';

// Aquesta targeta reutilitzable agrupa els continguts principals d’un formulari.
// Serveix per mantenir una presentació visual consistent a diferents pantalles.
class AppFormCard extends StatelessWidget {
  const AppFormCard({
    super.key,
    required this.child,
  });

  // Aquest bloc rep el contingut intern que s’ha de mostrar dins de la targeta.
  final Widget child;

  // Aquest mètode construeix la targeta amb el mateix estil base de formulari.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 460),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(32),
      ),
      child: child,
    );
  }
}
