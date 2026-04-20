import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/widgets/branding/cims_logo.dart';
import 'package:flutter/material.dart';
import 'profile_settings_controller.dart';
import 'widgets/profile_settings_option_tile.dart';

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
                  _buildTopBar(),
                  const SizedBox(height: 28),
                  _buildHeader(),
                  const Spacer(),
                  _buildSectionTitle(),
                  const SizedBox(height: 14),
                  _buildOptionsCard(),
                  const SizedBox(height: 28),
                  _buildLogoutButton(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Aquesta capçalera manté el patró visual net de la referència,
  // amb una única acció de tornar enrere.
  Widget _buildTopBar() {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: controller.onBackTap,
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Color(0xFF2F66FF),
        ),
      ),
    );
  }

  // Aquest bloc mostra el logotip de CiMS (temporalment?) i el nom de l’usuari
  // com a elements centrals de la pantalla.
  Widget _buildHeader() {
    return Column(
      children: [
        // Aquest contenidor dona protagonisme visual a la part superior
        // i fa de suport per al logotip o futura imatge de perfil.
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: CimsLogo(
              width: 68,
              height: 68,
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          controller.displayName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1D1D1F),
            height: 1,
          ),
        ),
      ],
    );
  }

  // Aquest text separa visualment el bloc d’opcions del compte.
  Widget _buildSectionTitle() {
    return const Padding(
      padding: EdgeInsets.only(left: 4),
      child: Text(
        'CONFIGURACIÓ',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.2,
          color: Color(0xFF9C9CA3),
        ),
      ),
    );
  }

  // Aquest contenidor agrupa les opcions principals de perfil.
  // En aquest sprint poden quedar visuals, excepte el logout.
  Widget _buildOptionsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        children: [
          ProfileSettingsOptionTile(
            icon: Icons.person_outline_rounded,
            title: 'Dades personals',
          ),
          SizedBox(height: 2),
          ProfileSettingsOptionTile(
            icon: Icons.lock_outline_rounded,
            title: 'Canviar contrasenya',
          ),
          SizedBox(height: 2),
          ProfileSettingsOptionTile(
            icon: Icons.delete_outline_rounded,
            title: 'Eliminar compte',
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  // Aquest botó és l’acció funcional principal de la pantalla en aquest sprint.
  Widget _buildLogoutButton() {
    return SizedBox(
      height: 58,
      child: OutlinedButton.icon(
        onPressed: controller.isLoggingOut ? null : controller.onLogoutTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(
            color: Color(0xFFF0CACA),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32),
          ),
          backgroundColor: Colors.transparent,
        ),
        // Aquest bloc adapta el contingut del botó segons l’estat actual,
        // mostrant càrrega mentre s’està tancant la sessió.
        icon: controller.isLoggingOut
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.logout_rounded,
                color: Color(0xFFD84C4C),
                size: 20,
              ),
        label: const Text(
          'Tancar sessió',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFFD84C4C),
          ),
        ),
      ),
    );
  }
}