import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../router/app_router.dart';
import 'app_start_controller.dart';

@RoutePage()
class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() => _AppStartScreenState();
}

class _AppStartScreenState extends State<AppStartScreen>
    with SingleTickerProviderStateMixin {
  late final AppStartController controller;
  late final AnimationController animationController;
  late final Animation<double> fadeAnimation;
  late final Animation<double> scaleAnimation;

  @override
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
  void dispose() {
    controller.removeListener(_handleControllerChanges);
    controller.dispose();
    animationController.dispose();
    super.dispose();
  }

  @override
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