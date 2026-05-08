import 'package:auto_route/auto_route.dart';
import 'package:cims/app/screens/ascent_edit/ascent_edit_controller.dart';
import 'package:cims/app/screens/ascent_edit/widgets/ascent_edit_form_card.dart';
import 'package:cims/app/widgets/buttons/primary_gradient_button.dart';
import 'package:cims/app/widgets/buttons/secondary_pill_button.dart';
import 'package:cims/core/entity/ascent.dart';
import 'package:flutter/material.dart';

// Aquesta pantalla permet consultar i editar una ascensió ja registrada.
// Reutilitza una estructura visual equivalent al registre d’ascensió,
// però inicialitza el formulari amb les dades existents.
@RoutePage()
class AscentEditScreen extends StatefulWidget {
  const AscentEditScreen({
    super.key,
    required this.ascent,
    required this.peakName,
    required this.altitude,
    required this.regions,
  });

  // Aquestes dades permeten mostrar el context de l’ascensió seleccionada
  // i carregar el formulari amb la informació ja registrada.
  final Ascent ascent;
  final String peakName;
  final int altitude;
  final List<String> regions;

  @override
  State<AscentEditScreen> createState() => _AscentEditScreenState();
}

class _AscentEditScreenState extends State<AscentEditScreen> {
  // Aquest controller centralitza l’estat del formulari d’edició.
  // Rep l’ascensió existent i prepara data i notes amb els valors guardats.
  late final AscentEditController controller;

  @override
  void initState() {
    super.initState();

    controller = AscentEditController(
      ascent: widget.ascent,
    )
      ..addListener(_handleControllerChanges)
      ..initialize();
 }

  // Aquest mètode resol les accions globals que el controller comunica a la vista.
  void _handleControllerChanges() {
    if (!mounted) return;

    if (controller.feedback == AscentEditFeedback.saved) {
      controller.consumeFeedback();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ascensió actualitzada correctament.'),
        ),
      );
    }

    if (controller.destination == AscentEditNavigationDestination.back) {
      controller.consumeNavigation();
      context.router.maybePop();
    }
  }

  // Aquest mètode obre el selector de calendari i actualitza la data local del formulari.
  Future<void> _selectAscentDate() async {
    if (controller.isLoading) {
      return;
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: controller.selectedAscentDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      controller.onAscentDateChanged(selectedDate);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_handleControllerChanges);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF2F2F4),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF0F5ADB),
              ),
              onPressed: controller.onCancelTap,
            ),
          ),
          body: SafeArea(
            top: false,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _AscentEditPeakSummary(
                      peakName: widget.peakName,
                      altitude: widget.altitude,
                      regions: widget.regions,
                    ),
                    const SizedBox(height: 24),
                    AscentEditFormCard(
                      controller: controller,
                      onDateTap: _selectAscentDate,
                    ),
                    if (controller.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _AscentEditErrorMessage(
                        message: controller.errorMessage!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryGradientButton(
                  label: 'Guardar canvis',
                  isLoading: controller.isLoading,
                  onPressed: controller.onSaveTap,
                ),
                const SizedBox(height: 12),
                SecondaryPillButton(
                  label: 'Cancel·lar',
                  enabled: !controller.isLoading,
                  onPressed: controller.onCancelTap,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Aquest widget mostra el resum del cim associat a l’ascensió.
// Dona context abans d’editar la data, les notes o les fotos.
class _AscentEditPeakSummary extends StatelessWidget {
  const _AscentEditPeakSummary({
    required this.peakName,
    required this.altitude,
    required this.regions,
  });

  final String peakName;
  final int altitude;
  final List<String> regions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(
          peakName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF17212B),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.terrain_rounded,
              size: 18,
              color: Color(0xFF0B57D0),
            ),
            const SizedBox(width: 8),
            Text(
              '$altitude m',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B57D0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: regions.isEmpty
              ? const [
                  _RegionChip(label: 'Sense comarca'),
                ]
              : regions
                  .map(
                    (region) => _RegionChip(label: region),
                  )
                  .toList(),
        ),
      ],
    );
  }
}

// Aquest petit widget pinta cada comarca com una etiqueta visual.
class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0B57D0),
        ),
      ),
    );
  }
}

// Aquest widget mostra els errors generals del formulari d’edició.
class _AscentEditErrorMessage extends StatelessWidget {
  const _AscentEditErrorMessage({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE84A4A),
        ),
      ),
    );
  }
}