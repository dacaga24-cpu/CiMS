import 'package:auto_route/auto_route.dart';
import 'package:cims/app/screens/ascent_history/ascent_history_controller.dart';
import 'package:cims/app/screens/ascent_history/widgets/ascent_history_content.dart';
import 'package:cims/core/entity/ascent.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:flutter/material.dart';

// Aquesta pantalla mostra l’historial d’ascensions d’un cim seleccionat.
// S’hi accedeix des de la llista d’últimes ascensions de la pantalla d’estadístiques.
@RoutePage()
class AscentHistoryScreen extends StatefulWidget {
  const AscentHistoryScreen({
    super.key,
    required this.peakId,
    required this.peakName,
    required this.altitude,
    required this.regions,
    this.imageUrl,
  });

  // Aquestes dades construeixen la capçalera del cim sense necessitar
  // una nova consulta al backend només per pintar informació ja disponible.
  final int peakId;
  final String peakName;
  final int altitude;
  final List<String> regions;
  final String? imageUrl;

  @override
  State<AscentHistoryScreen> createState() => _AscentHistoryScreenState();
}

// Aquesta classe prepara el controller i delega el contingut visual en widgets específics.
class _AscentHistoryScreenState extends State<AscentHistoryScreen> {
  late final AscentHistoryController controller;

  // Aquest mètode inicialitza la càrrega de l’historial del cim.
  @override
  void initState() {
    super.initState();
    controller = AscentHistoryController(peakId: widget.peakId)..initialize();
  }

  // Aquest mètode allibera el controller quan la pantalla deixa d’utilitzar-se.
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // Aquest mètode obre la pantalla d’edició de l’ascensió seleccionada.
  // Si l’edició o eliminació modifica dades, es refresca l’historial en tornar.
  Future<void> _openAscentEdit(Ascent ascent) async {
    final shouldRefresh = await context.router.root.push<bool>(
      AscentEditRoute(
        ascent: ascent,
        peakName: widget.peakName,
        altitude: widget.altitude,
        regions: widget.regions,
      ),
    );

    if (shouldRefresh == true) {
      await controller.onRefresh();
    }
  }

  // Aquest mètode construeix la pantalla completa amb una barra superior simple
  // i el contingut principal inspirat en el disseny de Figma.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF0F5ADB),
          ),
          onPressed: () {
            context.router.maybePop();
          },
        ),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return AscentHistoryContent(
            peakName: widget.peakName,
            altitude: widget.altitude,
            regions: widget.regions,
            ascents: controller.ascents,
            imageUrl: widget.imageUrl,
            isLoading: controller.isInitialLoading,
            errorMessage: controller.errorMessage,
            onRefresh: controller.onRefresh,
            onRetryTap: controller.onRetryTap,
            onAscentTap: _openAscentEdit,
          );
        },
      ),
    );
  }
}
