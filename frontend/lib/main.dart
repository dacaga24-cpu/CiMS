// main.dart
// Responsabilidad: Entry point de la aplicación Flutter.
// Configura los providers globales y arranca la app.
// NO contiene lógica de negocio ni widgets de UI.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'providers/peak_provider.dart';
import 'providers/ascent_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PeakProvider()),
        ChangeNotifierProvider(create: (_) => AscentProvider()),
      ],
      child: const CimsApp(),
    ),
  );
}
