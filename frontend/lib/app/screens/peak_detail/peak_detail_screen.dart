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
// Funciona fora de la navegació principal perquè s’obre des del catàleg, el mapa o altres pantalles.
@RoutePage()
class PeakDetailScreen extends StatefulWidget {
  const PeakDetailScreen({
    super.key,
    @PathParam('peakId') required this.peakId,
  });

  // Aquest identificador indica quin cim s’ha de carregar.
  // També permet obrir el detall directament des d’una URL del tipus /peaks/id.
  final int peakId;

  @override
  State<PeakDetailScreen> createState() => _PeakDetailScreenState();
}

// Aquest estat connecta la pantalla amb el controller del detall.
// També resol les navegacions derivades de les accions de l’usuari.
class _PeakDetailScreenState extends State<PeakDetailScreen> {
  // Aquestes dades mantenen el controller actiu i un possible error inicial.
  PeakDetailController? _controller;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  // Aquest mètode obre el mapa amb el cim actual seleccionat.
  // Substitueix la navegació principal perquè el mapa quedi com a secció activa.
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
  // Si l’identificador no és vàlid o la creació falla, mostra un error controlat.
  void _initializeController() {
    if (widget.peakId <= 0) {
      _initializationError =
          'L\'enllaç al cim no és vàlid. Torna al llistat i obre el cim des d\'allà.';
      return;
    }

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

  // Aquest mètode resol les navegacions demanades pel controller.
  // La pantalla executa les rutes per mantenir el controller separat del context visual.
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
  // En tornar al detall, refresca l’última ascensió mostrada a la pantalla.
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
  // Reutilitza les dades ja carregades per construir la capçalera de l’historial.
  Future<void> _openAscentHistory(Peak peak) async {
    await context.router.root.push(
      AscentHistoryRoute(
        peakId: peak.id,
        peakName: peak.name,
        altitude: peak.altitude,
        regions: peak.regions.map((region) => region.name).toList(),
        imageUrl: peak.imageUrl,
      ),
    );
  }

  // Aquest mètode mostra un missatge breu a la part inferior de la pantalla.
  // S’utilitza quan una acció no es pot completar amb les dades disponibles.
  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Aquest mètode allibera el controller quan la pantalla es tanca.
  // També elimina el listener per evitar notificacions després del tancament.
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
  // També cobreix el cas en què el controller no s’ha pogut inicialitzar.
  @override
  Widget build(BuildContext context) {
    final controller = _controller;

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
            weatherForecast: controller.weatherForecast,
            isWeatherLoading: controller.isWeatherLoading,
            weatherErrorMessage: controller.weatherErrorMessage,
            expandedWeatherDay: controller.expandedDay,
            expandedWeatherHourly: controller.expandedDay == null
                ? null
                : controller.hourlyForDay(controller.expandedDay!),
            isExpandedHourlyLoading: controller.expandedDay != null &&
                controller.isHourlyLoading(controller.expandedDay!),
            expandedHourlyError: controller.expandedDay == null
                ? null
                : controller.hourlyErrorFor(controller.expandedDay!),
            onRetryTap: controller.onRetryTap,
            onTargetTap: controller.onTargetTap,
            onFavoriteTap: controller.onFavoriteTap,
            onMapTap: _openPeakMap,
            onWeatherRetryTap: controller.onWeatherRetryTap,
            onWeatherDayTap: controller.toggleDayExpansion,
            onWeatherHourlyRetryTap: controller.onHourlyRetryTap,
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