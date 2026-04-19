import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../widgets/branding/cims_logo.dart';
import 'login_controller.dart';
import 'widgets/login_form_card.dart';
import 'widgets/login_register_text.dart';

// Aquesta pantalla mostra la interfície d’inici de sessió de l’aplicació.
// La seva funció és presentar el formulari, recollir la interacció de l’usuari
// i connectar la vista amb la lògica del controlador.
@RoutePage()
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Aquesta classe gestiona el comportament intern de la pantalla.
// Aquí es crea el controlador, s’escolten els seus canvis
// i es construeix tota la interfície que veu l’usuari.
class _LoginScreenState extends State<LoginScreen> {
  // Aquest controlador concentra l’estat i les accions del formulari de login.
  late final LoginController controller;

  // Aquest mètode prepara el controlador quan la pantalla es carrega per primera vegada.
  // També connecta la pantalla amb els canvis del controlador per poder reaccionar
  // quan cal navegar a una altra part de l’aplicació.
  @override
  void initState() {
    super.initState();
    controller = LoginController()..addListener(_handleControllerChanges);
  }

  // Aquest mètode escolta els canvis del controlador i actua quan cal canviar de pantalla.
  // En aquest cas, gestiona la navegació cap al registre o cap al dashboard
  // després d’un inici de sessió correcte.
  void _handleControllerChanges() {
    if (!mounted) return;

    if (controller.destination == LoginNavigationDestination.register) {
      controller.consumeNavigation();
      context.router.push(const RegisterRoute());
      return;
    }

    if (controller.destination == LoginNavigationDestination.dashboard) {
      controller.consumeNavigation();
      context.router.replace(const MainNavigationRoute());
    }
  }

  // Aquest mètode allibera el controlador quan la pantalla deixa d’utilitzar-se.
  @override
  void dispose() {
    controller.removeListener(_handleControllerChanges);
    controller.dispose();
    super.dispose();
  }

  // Aquest mètode construeix la part visual de la pantalla de login.
  // També ajusta la posició del formulari quan apareix el teclat
  // perquè els camps continuïn sent còmodes d’utilitzar.
  @override
  Widget build(BuildContext context) {
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
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: [
                  // Aquest bloc mostra el logotip a la part superior de la pantalla.
                  // Serveix per reforçar la identitat visual de l’aplicació en el punt d’accés.
                  const Align(
                    alignment: Alignment(0, -0.72),
                    child: CimsLogo(
                      width: 120,
                      height: 120,
                    ),
                  ),
                  // Aquest bloc conté tot el formulari d’inici de sessió
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
                            LoginFormCard(controller: controller),
                            const SizedBox(height: 20),
                            // Aquest bloc ofereix l’accés al registre
                            // per als usuaris que encara no tenen un compte creat.
                            LoginRegisterPrompt(
                              onTap: controller.onRegisterTap,
                            ),
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
