import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/screens/peak_detail/peak_detail_controller.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_bottom_action.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_description_card.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_empty_state.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_error_state.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_header.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_map_card.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_status_actions.dart';
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
  // La navegació real cap al mapa o cap al registre d’ascensió
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
        appBar: _buildAppBar(),
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
          appBar: _buildAppBar(),
          body: _buildBody(controller),
          bottomNavigationBar: PeakDetailBottomAction(
            onPressed: controller.onRegisterAscentTap,
          ),
        );
      },
    );
  }

  // Aquest mètode construeix la barra superior comuna de la pantalla.
  // Es manté transparent per conservar l’estil visual del detall del cim.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    );
  }

  // Aquest mètode decideix quin contingut s’ha de mostrar
  // segons l’estat actual de la càrrega del detall del cim.
  Widget _buildBody(PeakDetailController controller) {
    if (controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.errorMessage != null) {
      return PeakDetailErrorState(
        message: controller.errorMessage!,
        onRetryTap: controller.onRetryTap,
      );
    }

    final peak = controller.peak;
    if (peak == null) {
      return const PeakDetailEmptyState();
    }

    // Aquest bloc construeix el contingut principal del detall,
    // agrupant capçalera, estat, descripció i ubicació del cim.
    return RefreshIndicator(
      onRefresh: controller.onRetryTap,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          PeakDetailHeader(
            peak: peak,
            lastAscentDate: controller.lastAscentDate,
          ),
          const SizedBox(height: 18),
          PeakDetailStatusActions(
            isTarget: controller.peakStatus?.isTarget ?? false,
            isCompleted: controller.peakStatus?.isCompleted ?? false,
            isFavorite: controller.peakStatus?.isFavorite ?? false,
            areActionsEnabled: !controller.isUpdatingStatus,
            onTargetTap: controller.onTargetTap,
            onCompletedTap: controller.onCompletedTap,
            onFavoriteTap: controller.onFavoriteTap,
          ),
          if (controller.statusErrorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              controller.statusErrorMessage!,
              style: const TextStyle(
                color: Color(0xFFE84A4A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (controller.ascentsErrorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              controller.ascentsErrorMessage!,
              style: const TextStyle(
                color: Color(0xFFE84A4A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (peak.hasDescription) ...[
            const SizedBox(height: 18),
            PeakDetailDescriptionCard(
              peak: peak,
            ),
          ],
          const SizedBox(height: 18),
          PeakDetailMapCard(
            peak: peak,
            onTap: () => _openPeakMap(peak.id),
          ),
        ],
      ),
    );
  }
}