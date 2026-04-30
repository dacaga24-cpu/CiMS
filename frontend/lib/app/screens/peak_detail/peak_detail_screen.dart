import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/screens/peak_detail/peak_detail_controller.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_app_bar.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_bottom_action.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_content.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_error_state.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:flutter/material.dart';

// Aquesta pantalla mostra el detall d’un cim concret.
// És una pantalla independent de la tab bar perquè només s’hi arriba
// des del catàleg o des del mapa.
@RoutePage()
class PeakDetailScreen extends StatefulWidget {
  const PeakDetailScreen({
    super.key,
    required this.peakId,
  });

  // Aquesta propietat identifica quin cim s’ha de carregar
  // quan la pantalla s’obre.
  final int peakId;

  @override
  State<PeakDetailScreen> createState() => _PeakDetailScreenState();
}

// Aquest estat connecta la pantalla amb el controller del detall.
// També resol les navegacions derivades de les accions de l’usuari.
class _PeakDetailScreenState extends State<PeakDetailScreen> {
  // Aquest bloc guarda el controller real de la pantalla
  // i un possible missatge d’error si la seva creació falla d’entrada.
  PeakDetailController? _controller;
  String? _initializationError;

  // Aquest mètode prepara la pantalla en obrir-se.
  // Inicialitza el controller perquè el detall del cim es pugui carregar automàticament.
  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  // Obre la pantalla de mapa amb el cim actual seleccionat.
  // Així el mapa es carrega centrat en el marcador del cim.
  Future<void> _openPeakMap(int peakId) async {
    await context.router.root.replaceAll([
      MainNavigationRoute(
        children: [
          PeaksMapRoute(initialPeakId: peakId),
        ],
      ),
    ]);
  }

  // Aquest mètode crea el controller de manera segura.
  // Si falla la inicialització, la pantalla no peta i deixa visible
  // un missatge d’error per poder detectar millor el problema real.
  void _initializeController() {
    try {
      final controller = PeakDetailController(
        peakId: widget.peakId,
      );

      controller.addListener(_handleControllerChanges);
      controller.initialize();

      _controller = controller;
    } catch (error, stackTrace) {
      debugPrint('Error inicialitzant PeakDetailController: $error');
      debugPrintStack(stackTrace: stackTrace);

      _initializationError =
          'No s\'ha pogut obrir el detall del cim en aquest dispositiu.';
    }
  }

  // Aquest mètode resol les accions globals des de la vista.
  // La navegació real cap al mapa, cap al registre d’ascensió o cap a l’historial
  // es fa des de la pantalla per mantenir el controller separat del context visual.
  void _handleControllerChanges() {
    final controller = _controller;

    if (!mounted || controller == null) return;

    switch (controller.destination) {
      case PeakDetailDestination.none:
        return;

      case PeakDetailDestination.openMap:
        final peak = controller.peak;
        controller.consumeNavigation();

        if (peak == null || !peak.hasMapPosition) {
          _showInfoMessage(
            'No s\'ha pogut obrir la ubicació del cim.',
          );
          return;
        }

        _openPeakMap(peak.id);
        return;

      case PeakDetailDestination.registerAscent:
        final peak = controller.peak;
        controller.consumeNavigation();

        if (peak == null) {
          _showInfoMessage(
            'No s\'ha pogut preparar el registre d\'ascensió.',
          );
          return;
        }

        _openAscentRegister(controller, peak);
        return;

      case PeakDetailDestination.ascentHistory:
        final peak = controller.peak;
        controller.consumeNavigation();

        if (peak == null) {
          _showInfoMessage(
            'No s\'ha pogut obrir l\'historial d\'ascensions.',
          );
          return;
        }

        _openAscentHistory(peak);
        return;
    }
  }

  // Aquest mètode obre el formulari de registre d’ascensió.
  // Quan l’usuari torna al detall, es refresca la data de l’últim ascens
  // perquè la capçalera mostri la informació acabada de guardar al backend.
  Future<void> _openAscentRegister(
    PeakDetailController controller,
    Peak peak,
  ) async {
    await context.router.push(
      AscentRegisterRoute(peak: peak),
    );

    if (!mounted) {
      return;
    }

    await controller.refreshLastAscentDate();
  }

  // Aquest mètode obre l’historial d’ascensions del cim actual.
  // Reutilitza les dades ja carregades al detall per construir la capçalera.
  Future<void> _openAscentHistory(Peak peak) async {
    await context.router.root.push(
      AscentHistoryRoute(
        peakId: peak.id,
        peakName: peak.name,
        altitude: peak.altitude,
        regions: peak.regions.map((region) => region.name).toList(),
      ),
    );
  }

  // Aquest mètode mostra un missatge breu a la part inferior
  // per informar l’usuari de funcionalitats encara pendents o accions puntuals.
  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Aquest mètode allibera el controller quan la pantalla es tanca.
  // També elimina l’escolta activa per evitar notificacions innecessàries.
  @override
  void dispose() {
    final controller = _controller;

    if (controller != null) {
      controller.removeListener(_handleControllerChanges);
      controller.dispose();
    }

    super.dispose();
  }

  // Aquest mètode construeix l’estructura principal de la pantalla.
  // També contempla el cas en què el controller no s’hagi pogut preparar correctament.
  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    // Aquest primer cas cobreix els errors de preparació inicial de la pantalla
    // i evita que la vista intenti funcionar sense controller disponible.
    if (_initializationError != null || controller == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: const PeakDetailAppBar(),
        body: PeakDetailErrorState(
          message: _initializationError ??
              'No s\'ha pogut inicialitzar la pantalla de detall.',
        ),
      );
    }

    // Aquest bloc escolta els canvis del controller i reconstrueix la pantalla
    // quan canvia la càrrega, les dades o algun estat visual del detall.
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          appBar: const PeakDetailAppBar(),
          body: PeakDetailContent(
            isLoading: controller.isLoading,
            errorMessage: controller.errorMessage,
            peak: controller.peak,
            peakStatus: controller.peakStatus,
            lastAscentDate: controller.lastAscentDate,
            isUpdatingStatus: controller.isUpdatingStatus,
            statusErrorMessage: controller.statusErrorMessage,
            ascentsErrorMessage: controller.ascentsErrorMessage,
            onRetryTap: controller.onRetryTap,
            onTargetTap: controller.onTargetTap,
            onCompletedTap: controller.onCompletedTap,
            onFavoriteTap: controller.onFavoriteTap,
            onMapTap: _openPeakMap,
          ),
          bottomNavigationBar: PeakDetailBottomAction(
            onPressed: controller.onRegisterAscentTap,
            onHistoryPressed: controller.onAscentHistoryTap,
          ),
        );
      },
    );
  }
}