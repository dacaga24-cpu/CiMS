import 'package:flutter/material.dart';

// Aquest widget mostra l’estat de càrrega inicial de la pantalla.
// Es manté separat per evitar carregar la pantalla principal amb lògica visual repetida.
class StatsLoadingState extends StatelessWidget {
  const StatsLoadingState({super.key});

  // Aquest mètode construeix l’indicador visual que informa l’usuari
  // que les estadístiques encara s’estan carregant.
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
