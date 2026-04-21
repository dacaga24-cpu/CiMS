import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'register_controller.dart';
import 'widgets/register_form_card.dart';
import 'widgets/register_terms_text.dart';

// Aquesta pantalla mostra el formulari de registre de l’aplicació.
// La seva funció és recollir les dades necessàries per crear un compte nou
// i connectar la interfície amb la lògica que controla el procés de registre.
@RoutePage()
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// Aquesta classe gestiona el comportament intern de la pantalla.
// Aquí es crea el controlador, s’escolten els seus canvis
// i es construeix tota la interfície que veu l’usuari.
class _RegisterScreenState extends State<RegisterScreen> {
  // Aquest controlador concentra l’estat i les accions del formulari de registre.
  late final RegisterController controller;

  // Aquest mètode prepara el controlador quan la pantalla es carrega.
  // També connecta la vista amb els canvis que poden requerir navegació o avisos.
  @override
  void initState() {
    super.initState();
    controller = RegisterController()..addListener(_handleControllerChanges);
  }

  // Aquest mètode reacciona als canvis del controlador.
  // Serveix per gestionar la navegació a altres pantalles
  // o mostrar accions puntuals relacionades amb el registre.
  void _handleControllerChanges() {
    if (!mounted) return;

    if (controller.destination == RegisterNavigationDestination.login) {
      controller.consumeNavigation();

      // Aquest bloc torna l’usuari al login després del registre,
      // aprofitant la navegació existent si n’hi ha una de prèvia.
      if (context.router.canPop()) {
        context.router.pop();
      } else {
        context.router.replace(const LoginRoute());
      }
      return;
    }

    if (controller.destination == RegisterNavigationDestination.terms) {
      controller.consumeNavigation();

      // Aquest diàleg informa l’usuari que l’accés als termes del servei
      // encara no està disponible dins de l’aplicació.
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Termes de Servei'),
            content: const Text(
              'Aquesta secció encara no està disponible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('D’acord'),
              ),
            ],
          );
        },
      );
    }
  }

  // Aquest mètode allibera el controlador quan la pantalla deixa d’utilitzar-se.
  @override
  void dispose() {
    controller.removeListener(_handleControllerChanges);
    controller.dispose();
    super.dispose();
  }

  // Aquest mètode construeix la part visual de la pantalla de registre.
  // També ajusta la posició del formulari quan apareix el teclat,
  // perquè els camps continuïn sent accessibles mentre l’usuari escriu.
  @override
  Widget build(BuildContext context) {
    // Aquest càlcul adapta el desplaçament inferior del formulari
    // perquè continuï sent visible quan el teclat està obert.
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final formBottomOffset = keyboardInset > 0 ? keyboardInset : 56.0;

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
                            RegisterFormCard(controller: controller),
                            const SizedBox(height: 18),
                            // Aquest bloc informa l’usuari que el registre implica l’acceptació
                            // de les condicions bàsiques del servei.
                            RegisterTermsText(
                              isLoading: controller.isLoading,
                              onTapTerms: controller.onTermsTap,
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