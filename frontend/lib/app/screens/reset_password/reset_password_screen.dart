import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/widgets/branding/cims_logo.dart';
import 'package:cims/app/widgets/layout/app_responsive.dart';
import 'package:flutter/material.dart';
import 'reset_password_controller.dart';
import 'widgets/reset_password_form_card.dart';

// Aquesta pantalla permet definir una nova contrasenya a partir d’un enllaç de recuperació.
// Llegeix el token de la URL i delega la validació i l’enviament al controller.
@RoutePage()
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

// Aquest estat connecta la pantalla amb el controller de recuperació.
// També resol la navegació de retorn cap al login quan el procés finalitza.
class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final ResetPasswordController controller;

  @override
  void initState() {
    super.initState();

    final token = Uri.base.queryParameters['token'] ?? '';

    controller = ResetPasswordController(token: token)
      ..addListener(_handleControllerChanges);
  }

  // Aquest mètode resol la navegació demanada pel controller.
  // Quan la contrasenya s’ha actualitzat o l’usuari torna enrere, envia la pantalla al login.
  void _handleControllerChanges() {
    if (!mounted) return;

    if (controller.destination == ResetPasswordNavigationDestination.login) {
      controller.consumeNavigation();

      if (context.router.canPop()) {
        context.router.pop();
      } else {
        context.router.replace(const LoginRoute());
      }
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

  // Aquest mètode construeix la pantalla de canvi de contrasenya.
  // Adapta la distribució del logo i del formulari segons la mida de pantalla i el teclat.
  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final formBottomOffset = keyboardInset > 0 ? keyboardInset : 72.0;
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
              child: isCompact
                  ? Stack(
                      children: [
                        const Align(
                          alignment: Alignment(0, -0.72),
                          child: CimsLogo(
                            width: 120,
                            height: 120,
                          ),
                        ),
                        AnimatedPadding(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          padding: EdgeInsets.only(bottom: formBottomOffset),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: SingleChildScrollView(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 16, 24, 24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 12),
                                  ResetPasswordFormCard(
                                    controller: controller,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : AnimatedPadding(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.only(bottom: keyboardInset),
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 40,
                          ),
                          child: ResponsiveConstrainedBox(
                            maxWidth: AppResponsive.formMaxWidth(context),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CimsLogo(
                                  width: 112,
                                  height: 112,
                                ),
                                const SizedBox(height: 28),
                                ResetPasswordFormCard(controller: controller),
                              ],
                            ),
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