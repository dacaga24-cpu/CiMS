import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../router/app_router.dart';

import 'login_controller.dart';

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
      context.router.replace(const DashboardRoute());
    }
  }

  // Aquest mètode allibera el controlador quan la pantalla deixa d’utilitzar-se.
  @override
  void dispose() {
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
                  Align(
                    alignment: const Alignment(0, -0.72),
                    child: SvgPicture.asset(
                      'assets/images/cims_logo.svg',
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
                            // Aquesta targeta agrupa els camps principals del formulari,
                            // els missatges de validació i l’acció principal d’iniciar sessió.
                            Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 460),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 28,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDEDED),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Correu',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _InputField(
                                    controller: controller.emailController,
                                    hintText: 'elteu@correu.com',
                                    keyboardType: TextInputType.emailAddress,
                                    obscureText: false,
                                    enabled: !controller.isLoading,
                                    onChanged: controller.onEmailChanged,
                                  ),
                                  // Aquest missatge es mostra quan el correu no té un format correcte.
                                  if (controller.hasInvalidEmail) ...[
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Introdueix un correu electrònic vàlid',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 26),
                                  // Aquest bloc mostra el camp de contrasenya
                                  // i l’accés a la futura recuperació de contrasenya.
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Contrasenya',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E1E1E),
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: controller.onForgotPasswordTap,
                                        child: const Text(
                                          'Has oblidat la contrasenya?',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0B57D0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _InputField(
                                    controller: controller.passwordController,
                                    hintText: '••••••••••••',
                                    keyboardType: TextInputType.text,
                                    obscureText: controller.obscurePassword,
                                    enabled: !controller.isLoading,
                                    onChanged: controller.onPasswordChanged,
                                    onSubmitted: (_) => controller.onLoginTap(),
                                    suffixIcon: IconButton(
                                      onPressed: controller.isLoading
                                          ? null
                                          : controller.togglePasswordVisibility,
                                      icon: Icon(
                                        controller.obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF6E6E73),
                                      ),
                                    ),
                                  ),
                                  // Aquest missatge informa que la contrasenya és obligatòria.
                                  if (controller.hasEmptyPassword) ...[
                                    const SizedBox(height: 8),
                                    const Text(
                                      'La contrasenya és obligatòria',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                  // Aquest bloc mostra un error general del procés de login,
                                  // com ara credencials incorrectes o problemes de connexió.
                                  if (controller.errorMessage != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      controller.errorMessage!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 34),
                                  // Aquest botó inicia el procés d’autenticació.
                                  // Quan hi ha una petició en curs, es desactiva i mostra un indicador de càrrega.
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(28),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF0E63F4),
                                            Color(0xFF0047C7),
                                          ],
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x220047C7),
                                            blurRadius: 12,
                                            offset: Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: controller.isLoading
                                            ? null
                                            : () => controller.onLoginTap(),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          disabledBackgroundColor:
                                              Colors.transparent,
                                          disabledForegroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(28),
                                          ),
                                        ),
                                        child: controller.isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Colors.white,
                                                  ),
                                                ),
                                              )
                                            : const Text(
                                                'Iniciar Sessió',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Aquest bloc ofereix l’accés al registre
                            // per als usuaris que encara no tenen un compte creat.
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Encara no tens un compte? ',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF3C3C43),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: controller.onRegisterTap,
                                  child: const Text(
                                    'Registra\'t',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0B57D0),
                                    ),
                                  ),
                                ),
                              ],
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

// Aquest component reutilitzable representa un camp de text amb el mateix estil visual.
// Serveix per mantenir coherència entre els camps del formulari i evitar repetir codi.
class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    required this.obscureText,
    this.suffixIcon,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
  });

  // Aquest bloc defineix la informació necessària per configurar el camp:
  // el text introduït, el tipus d’entrada, si el contingut s’ha d’ocultar
  // i les accions opcionals relacionades amb els canvis o l’enviament.
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  // Aquest mètode construeix visualment el camp de text amb l’estil comú del formulari.
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFFB0B3B8),
            fontSize: 18,
          ),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
