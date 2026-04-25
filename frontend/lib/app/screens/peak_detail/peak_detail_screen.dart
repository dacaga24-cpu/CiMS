import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/screens/peak_detail/peak_detail_controller.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_header.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_map_card.dart';
import 'package:cims/app/screens/peak_detail/widgets/peak_detail_status_actions.dart';
import 'package:cims/app/widgets/buttons/primary_gradient_button.dart';
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
  // es completarà en una iteració posterior.
  void _handleControllerChanges() {
    final controller = _controller;

    if (!mounted || controller == null) return;

    switch (controller.destination) {
      case PeakDetailDestination.none:
        return;
      case PeakDetailDestination.openMap:
        controller.consumeNavigation();
        _showInfoMessage(
          'La connexió directa amb el mapa del cim encara està pendent d\'integrar.',
        );
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

        context.router.push(
          AscentRegisterRoute(peak: peak),
        );
        return;
    }
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 42,
                  color: Color(0xFF9AA3B2),
                ),
                const SizedBox(height: 14),
                Text(
                  _initializationError ??
                      'No s\'ha pogut inicialitzar la pantalla de detall.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          body: _buildBody(controller),
          bottomNavigationBar: _buildBottomAction(controller),
        );
      },
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: Color(0xFF9AA3B2),
              ),
              const SizedBox(height: 14),
              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: controller.onRetryTap,
                child: const Text('Torna-ho a provar'),
              ),
            ],
          ),
        ),
      );
    }

    final peak = controller.peak;
    if (peak == null) {
      return const Center(
        child: Text('No s\'ha trobat informació del cim'),
      );
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
          if (peak.hasDescription) ...[
            const SizedBox(height: 18),
            _buildDescriptionCard(peak),
          ],
          const SizedBox(height: 18),
          PeakDetailMapCard(
            peak: peak,
            onTap: controller.onMapTap,
          ),
        ],
      ),
    );
  }

  // Aquest bloc mostra la descripció només si el backend l’ha informat.
  Widget _buildDescriptionCard(Peak peak) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descripció',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17212B),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            peak.description!,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }

  // Aquest botó fixa l’acció principal a la part inferior de la pantalla.
  Widget _buildBottomAction(PeakDetailController controller) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: PrimaryGradientButton(
        label: 'Registrar ascensió',
        icon: Icons.north_east_rounded,
        onPressed: controller.onRegisterAscentTap,
      ),
    );
  }
}