import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/widgets/layout/app_responsive.dart';
import 'package:flutter/material.dart';
import 'register_controller.dart';
import 'widgets/register_form_card.dart';

// Aquesta pantalla mostra el formulari de registre d’un nou usuari.
// Manté la part visual separada del controller i resol la navegació cap al login.
@RoutePage()
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// Aquest estat connecta la pantalla amb el controller de registre.
// Escolta els canvis del controller per reaccionar a la navegació pendent.
class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterController controller;

  @override
  void initState() {
    super.initState();
    controller = RegisterController()..addListener(_handleControllerChanges);
  }

  // Aquest mètode resol la navegació demanada pel controller.
  // Quan el registre finalitza o l’usuari vol tornar, envia la pantalla al login.
  void _handleControllerChanges() {
    if (!mounted) return;

    if (controller.destination == RegisterNavigationDestination.login) {
      controller.consumeNavigation();

      if (context.router.canPop()) {
        context.router.pop();
      } else {
        context.router.replace(const LoginRoute());
      }
      return;
    }
  }

  // Aquest mètode allibera el controller quan la pantalla es tanca.
  // També elimina el listener per evitar notificacions sobre una pantalla destruïda.
  @override
  void dispose() {
    controller.removeListener(_handleControllerChanges);
    controller.dispose();
    super.dispose();
  }

  // Aquest mètode construeix la pantalla de registre.
  // Adapta la posició del formulari segons la mida de pantalla i el teclat visible.
  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final formBottomOffset = keyboardInset > 0 ? keyboardInset : 56.0;
    final isCompact = AppResponsive.isCompact(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF2F2F4),
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(
                  bottom: isCompact ? formBottomOffset : keyboardInset,
                ),
                child: Align(
                  alignment:
                      isCompact ? Alignment.bottomCenter : Alignment.center,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 24 : 32,
                      16,
                      isCompact ? 24 : 32,
                      24,
                    ),
                    child: ResponsiveConstrainedBox(
                      maxWidth: AppResponsive.formMaxWidth(context),
                      child: RegisterFormCard(controller: controller),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}