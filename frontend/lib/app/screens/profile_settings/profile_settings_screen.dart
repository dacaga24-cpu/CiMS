import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'profile_settings_controller.dart';
import 'widgets/profile_settings_header.dart';
import 'widgets/profile_settings_logout_button.dart';
import 'widgets/profile_settings_options_card.dart';
import 'widgets/profile_settings_section_title.dart';
import 'widgets/profile_settings_top_bar.dart';

// Aquesta pantalla mostra la configuració bàsica del compte.
// En aquest sprint es prioritza el disseny visual i el logout funcional.
@RoutePage()
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({
    super.key,
    this.onLogout,
  });

  // Aquesta funció permet connectar la pantalla amb la lògica real de logout.
  final Future<void> Function()? onLogout;

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

// Aquesta classe gestiona el comportament intern de la pantalla de configuració.
// S’encarrega de crear el controller, reaccionar als seus canvis
// i construir la interfície segons l’estat actual del perfil.
class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  // Aquest controlador concentra la càrrega del perfil,
  // la gestió d’errors i l’acció de tancar sessió.
  late final ProfileSettingsController controller;

  // Aquest mètode prepara el controller quan la pantalla es crea
  // i inicia la càrrega inicial de les dades del perfil.
  @override
  void initState() {
    super.initState();
    controller = ProfileSettingsController(
      logoutAction: widget.onLogout,
    )..addListener(_handleControllerChanges);

    controller.loadProfile();
  }

  // Aquest mètode escolta els canvis del controller i resol la navegació real
  // des de la vista, mantenint el controller desacoblat de la UI.
  void _handleControllerChanges() {
    if (!mounted) return;

    if (controller.destination == ProfileSettingsDestination.back) {
      controller.consumeNavigation();
      context.router.maybePop();
      return;
    }

    if (controller.destination == ProfileSettingsDestination.login) {
      controller.consumeNavigation();
      context.router.root.replaceAll([
        const LoginRoute(),
      ]);
      return;
    }

    // Aquest bloc mostra els errors puntuals a l’usuari
    // sense deixar-los persistint més temps del necessari a l’estat.
    if (controller.errorMessage != null) {
      final errorMessage = controller.errorMessage!;
      controller.consumeErrorMessage();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    }
  }

  // Aquest mètode allibera el controller quan la pantalla deixa d’utilitzar-se.
  @override
  void dispose() {
    controller.removeListener(_handleControllerChanges);
    controller.dispose();
    super.dispose();
  }

  // Aquest mètode construeix la pantalla de configuració del perfil.
  // Organitza la capçalera, les opcions del compte i el botó de tancar sessió.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileSettingsTopBar(
                    onBackTap: controller.onBackTap,
                  ),
                  const SizedBox(height: 28),
                  ProfileSettingsHeader(
                    displayName: controller.displayName,
                  ),
                  const Spacer(),
                  const ProfileSettingsSectionTitle(),
                  const SizedBox(height: 14),
                  const ProfileSettingsOptionsCard(),
                  const SizedBox(height: 28),
                  ProfileSettingsLogoutButton(
                    isLoggingOut: controller.isLoggingOut,
                    onLogoutTap: controller.onLogoutTap,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
