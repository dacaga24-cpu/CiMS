import 'package:auto_route/auto_route.dart';
import 'package:cims/app/screens/ascent_verification/ascent_verification_controller.dart';
import 'package:cims/app/screens/ascent_verification/widgets/ascent_verification_capture_card.dart';
import 'package:flutter/material.dart';

// Aquesta pantalla actua com a punt d’entrada del flux de verificació ràpida.
// S’obre des del botó central i inicia automàticament la preparació de la captura,
// evitant que l’usuari hagi de confirmar dues vegades la mateixa acció.
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
    controller = AscentVerificationController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.prepareCapture();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F4F6),
        elevation: 0,
        foregroundColor: const Color(0xFF1D2939),
        title: const Text('Verificant ascensió'),
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
              selectedNearbyPeakCandidate: controller.selectedNearbyPeakCandidate,
              isLoadingNearbyPeaks: controller.isLoadingNearbyPeaks,
              onNearbyPeakTap: controller.selectNearbyPeakCandidate,
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
