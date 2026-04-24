import 'package:auto_route/auto_route.dart';
import 'package:cims/app/screens/ascent_register/ascent_register_controller.dart';
import 'package:cims/app/screens/ascent_register/widgets/ascent_register_form_card.dart';
import 'package:cims/app/screens/ascent_register/widgets/ascent_register_peak_summary.dart';
import 'package:cims/app/widgets/buttons/primary_gradient_button.dart';
import 'package:cims/app/widgets/buttons/secondary_pill_button.dart';
import 'package:cims/core/entity/peak.dart';
import 'package:flutter/material.dart';

// Aquesta pantalla mostra el formulari visual de registre d’una ascensió.
// En aquesta iteració només cobreix la presentació i la navegació del flux,
// deixant el desat real per quan backend estigui preparat.
@RoutePage()
class AscentRegisterScreen extends StatefulWidget {
  const AscentRegisterScreen({
    super.key,
    required this.peak,
  });

  // Aquest cim arriba des de la pantalla anterior i permet mostrar
  // el context sobre quina ascensió s’està registrant.
  final Peak peak;

  @override
  State<AscentRegisterScreen> createState() => _AscentRegisterScreenState();
}

class _AscentRegisterScreenState extends State<AscentRegisterScreen> {
  // Aquest controller centralitza l’estat del formulari i les accions
  // que la pantalla ha d’interpretar, com la navegació o els avisos.
  late final AscentRegisterController controller;

  @override
  void initState() {
    super.initState();

    // Aquí es prepara el controller i s’escolten els seus canvis
    // per reaccionar des de la vista quan calgui.
    controller = AscentRegisterController()
      ..addListener(_handleControllerChanges);
  }

  // Aquest mètode resol les accions globals que el controller comunica a la vista.
  void _handleControllerChanges() {
    if (!mounted) return;

    if (controller.destination == AscentRegisterNavigationDestination.back) {
      controller.consumeNavigation();
      context.router.pop();
      return;
    }

    if (controller.feedback == AscentRegisterFeedback.pendingSave) {
      controller.consumeFeedback();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La pantalla ja està preparada, però el registre real encara no està connectat amb el backend.',
          ),
        ),
      );
    }
  }

  // Aquest mètode obre el selector de calendari i actualitza la data local del formulari.
  Future<void> _selectAscentDate() async {
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
    // Aquí es netegen els recursos associats al controller
    // per evitar deixar escoltes actives quan la pantalla es tanca.
    controller.removeListener(_handleControllerChanges);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // La pantalla es reconstrueix quan canvia l’estat del controller,
    // de manera que el formulari i les accions sempre mostren el valor actual.
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
                    // Aquest resum dona context visual del cim abans
                    // d’omplir les dades de l’ascensió.
                    AscentRegisterPeakSummary(peak: widget.peak),
                    const SizedBox(height: 24),

                    // Aquesta targeta concentra els camps del formulari
                    // perquè el registre sigui més clar i ordenat.
                    AscentRegisterFormCard(
                      controller: controller,
                      onDateTap: _selectAscentDate,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Aquesta zona fixa manté visibles les accions principals
          // del flux perquè l’usuari pugui confirmar o cancel·lar fàcilment.
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryGradientButton(
                  label: 'Confirmar',
                  onPressed: controller.onConfirmTap,
                ),
                const SizedBox(height: 12),
                SecondaryPillButton(
                  label: 'Cancel·lar',
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