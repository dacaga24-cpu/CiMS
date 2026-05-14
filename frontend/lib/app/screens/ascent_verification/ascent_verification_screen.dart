import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/screens/ascent_verification/ascent_verification_controller.dart';
import 'package:cims/app/screens/ascent_verification/widgets/ascent_verification_capture_card.dart';
import 'package:flutter/material.dart';

// Aquesta pantalla mostra el flux de verificació ràpida d’una ascensió.
// El controller captura la ubicació, proposa cims propers i obre la càmera
// quan l’usuari ja ha seleccionat quin cim vol verificar.
@RoutePage()
class AscentVerificationScreen extends StatefulWidget {
  const AscentVerificationScreen({super.key});

  @override
  State<AscentVerificationScreen> createState() =>
      _AscentVerificationScreenState();
}

class _AscentVerificationScreenState extends State<AscentVerificationScreen> {
  late final AscentVerificationController controller;

  @override
  void initState() {
    super.initState();

    controller = AscentVerificationController()
      ..addListener(_handleControllerNavigation);

    controller.prepareCapture();
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerNavigation);
    controller.dispose();
    super.dispose();
  }

  // Aquest mètode executa la navegació que demana el controller després de crear
  // l’ascensió verificada. La pantalla fa la navegació real per mantenir el controller
  // separat de la capa visual.
  void _handleControllerNavigation() {
    if (!mounted) {
      return;
    }

    final destination = controller.destination;

    if (destination == AscentVerificationDestination.none) {
      return;
    }

    final createdAscent = controller.createdAscent;
    final selectedCandidate = controller.selectedNearbyPeakCandidate;

    controller.consumeNavigation();

    if (destination == AscentVerificationDestination.back) {
      context.router.maybePop(true);
      return;
    }

    if (destination == AscentVerificationDestination.editAscent &&
        createdAscent != null &&
        selectedCandidate != null) {
      final peak = selectedCandidate.peak;

      context.router.replace(
        AscentEditRoute(
          ascent: createdAscent,
          peakName: peak.name,
          altitude: peak.altitude,
          regions: peak.regions.map((region) => region.name).toList(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F6),
        elevation: 0,
        foregroundColor: const Color(0xFF1D2939),
        title: const Text('Verificar ascensió'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return AscentVerificationCaptureCard(
              isLoading: controller.isPreparingCapture,
              message: controller.message,
              errorMessage: controller.errorMessage,
              position: controller.position,
              capturedAt: controller.capturedAt,
              photoBytes: controller.photoBytes,
              nearbyPeakCandidates: controller.nearbyPeakCandidates,
              selectedNearbyPeakCandidate:
                  controller.selectedNearbyPeakCandidate,
              isLoadingNearbyPeaks: controller.isLoadingNearbyPeaks,
              onNearbyPeakTap: controller.selectNearbyPeakCandidate,
              onCapturePhotoTap: controller.capturePhoto,
              onCreateVerifiedAscentTap: controller.createVerifiedAscent,
              onCompleteLaterTap: controller.completeLater,
              onRetryTap: controller.retryCapture,
            );
          },
        ),
      ),
    );
  }
}