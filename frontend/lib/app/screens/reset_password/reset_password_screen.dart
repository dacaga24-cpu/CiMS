import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/widgets/branding/cims_logo.dart';
import 'package:flutter/material.dart';
import 'reset_password_controller.dart';
import 'widgets/reset_password_form_card.dart';

// Aquesta pantalla mostra el formulari per definir una nova contrasenya.
// La seva funció és permetre a l’usuari escriure i confirmar la nova contrasenya
// i connectar la vista amb la lògica del controlador.
@RoutePage()
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

// Aquesta classe gestiona el comportament intern de la pantalla.
// Aquí es crea el controlador, s’escolten els seus canvis
// i es construeix tota la interfície que veu l’usuari.
class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // Aquest controlador concentra l’estat i les accions del formulari
  // de canvi de contrasenya.
  late final ResetPasswordController controller;

  // Aquest mètode prepara el controlador quan la pantalla es carrega.
  // També connecta la vista amb els canvis que poden requerir navegació.
  @override
  void initState() {
    super.initState();

    final token = Uri.base.queryParameters['token'] ?? '';

    controller = ResetPasswordController(token: token)
      ..addListener(_handleControllerChanges);
  }

  // Aquest mètode reacciona als canvis del controlador.
  // Serveix per tornar a l’inici de sessió quan el flux s’ha completat
  // o quan l’usuari decideix sortir d’aquesta pantalla.
  void _handleControllerChanges() {
    if (!mounted) return;

    if (controller.destination == ResetPasswordNavigationDestination.login) {
      controller.consumeNavigation();

      // Aquest bloc reutilitza la navegació existent si és possible
      // i, si no, força el retorn directe a la pantalla de login.
      if (context.router.canPop()) {
        context.router.pop();
      } else {
        context.router.replace(const LoginRoute());
      }
    }
  }

  // Aquest mètode allibera el controlador quan la pantalla deixa d’utilitzar-se.
  @override
  void dispose() {
    controller.removeListener(_handleControllerChanges);
    controller.dispose();
    super.dispose();
  }

  // Aquest mètode construeix la part visual de la pantalla.
  // També ajusta la posició del formulari quan apareix el teclat
  // perquè els camps continuïn sent còmodes d’utilitzar.
  @override
  Widget build(BuildContext context) {
    // Aquest càlcul adapta el desplaçament inferior del formulari
    // per mantenir-lo visible mentre l’usuari està escrivint.
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final formBottomOffset = keyboardInset > 0 ? keyboardInset : 72.0;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF2F2F4),
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: GestureDetector(
              // Aquesta acció permet tancar el teclat quan l’usuari toca fora dels camps,
              // millorant la comoditat d’ús de la pantalla.
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: [
                  // Aquest bloc mostra el logotip a la part superior de la pantalla.
                  // Serveix per mantenir la coherència visual amb la resta del flux d’accés.
                  const Align(
                    alignment: Alignment(0, -0.72),
                    child: CimsLogo(
                      width: 120,
                      height: 120,
                    ),
                  ),
                  // Aquest bloc conté el formulari principal
                  // i el desplaça suaument quan apareix el teclat.
                  AnimatedPadding(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.only(bottom: formBottomOffset),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 12),
                            ResetPasswordFormCard(controller: controller),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
