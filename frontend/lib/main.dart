import 'package:flutter/material.dart';
import 'package:cims/app/router/app_router.dart';

// Aquest mètode posa en marxa l’aplicació i carrega el punt d’entrada principal.
void main() {
  runApp(const MyApp());
}

// Aquest widget representa la base de l’aplicació.
// La seva funció és preparar la configuració general i definir des d’on es gestionarà la navegació entre pantalles.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Aquest objecte centralitza la configuració de navegació de l’aplicació.
  // Gràcies a això, les diferents pantalles es poden organitzar i connectar de manera coherent.
  static final AppRouter _appRouter = AppRouter();

  // Aquest mètode construeix l’estructura principal visible de l’aplicació.
  // Aquí es configura que la navegació es farà a partir del sistema de rutes definit prèviament.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: true,
      routerConfig: _appRouter.config(),
    );
  }
}