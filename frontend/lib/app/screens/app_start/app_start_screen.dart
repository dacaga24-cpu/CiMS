import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../router/app_router.dart';
import 'app_start_controller.dart';

@RoutePage()
// Aquesta pantalla actua com a punt d’entrada visual de l’aplicació.
// Mostra el logotip inicial, prepara una animació de presentació
// i decideix a quina pantalla s’ha d’enviar l’usuari segons el seu estat de sessió.
class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() => _AppStartScreenState();
}

// Aquesta classe gestiona la lògica interna de la pantalla inicial.
// Aquí es controla tant la comprovació de sessió com l’animació
// que es mostra mentre es decideix el següent pas dins de l’aplicació.
class _AppStartScreenState extends State<AppStartScreen>
    with SingleTickerProviderStateMixin {
  // Aquest bloc agrupa els elements principals que necessita la pantalla:
  // un controlador per decidir la navegació i diverses animacions per donar
  // una entrada visual més suau al logotip.
  late final AppStartController controller;
  late final AnimationController animationController;
  late final Animation<double> fadeAnimation;
  late final Animation<double> scaleAnimation;

  @override
  // Aquest mètode prepara tot el necessari quan la pantalla es carrega.
  // Inicialitza la lògica que decidirà la navegació, configura les animacions
  // del logotip i posa en marxa tant l’efecte visual com la comprovació inicial.
  void initState() {
    super.initState();

    controller = AppStartController(
      hasSavedSession: () async => false, // TODO: substituir per la comprovació real de sessió guardada
    )..addListener(_handleControllerChanges);

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOutBack,
      ),
    );

    animationController.forward();
    controller.initialize();
  }

  // Aquest mètode respon als canvis del controlador.
  // Quan el sistema ja sap on ha d’anar l’usuari, fa la navegació
  // cap a la pantalla de login o cap al dashboard principal.
  void _handleControllerChanges() {
    if (!mounted) return;

    if (controller.destination == AppStartDestination.login) {
      controller.consumeNavigation();
      context.router.replace(const LoginRoute());
      return;
    }

    if (controller.destination == AppStartDestination.dashboard) {
      controller.consumeNavigation();
      context.router.replace(const DashboardRoute());
    }
  }

  @override
  // Aquest mètode allibera els recursos utilitzats per la pantalla
  // quan deixa d’estar activa, evitant que quedin processos oberts innecessàriament.
  void dispose() {
    controller.removeListener(_handleControllerChanges);
    controller.dispose();
    animationController.dispose();
    super.dispose();
  }

  @override
  // Aquest mètode construeix la part visual de la pantalla.
  // Mostra únicament el logotip centrat amb una entrada progressiva,
  // creant una pantalla inicial simple i neta mentre es prepara la navegació.
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F4),
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: fadeAnimation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: Transform.translate(
                offset: const Offset(0, -70),
                child: SvgPicture.asset(
                  'assets/images/cims_logo.svg',
                  width: 110,
                  height: 110,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}