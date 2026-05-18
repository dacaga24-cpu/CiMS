import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:cims/app/widgets/layout/app_responsive.dart';
import 'package:flutter/material.dart';
import 'register_controller.dart';
import 'widgets/register_form_card.dart';
import 'widgets/register_terms_text.dart';

@RoutePage()
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterController controller;

  @override
  void initState() {
    super.initState();
    controller = RegisterController()..addListener(_handleControllerChanges);
  }

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

    if (controller.destination == RegisterNavigationDestination.terms) {
      controller.consumeNavigation();

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
                child: const Text("D'acord"),
              ),
            ],
          );
        },
      );
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RegisterFormCard(controller: controller),
                          const SizedBox(height: 18),
                          RegisterTermsText(
                            isLoading: controller.isLoading,
                            onTapTerms: controller.onTermsTap,
                          ),
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
