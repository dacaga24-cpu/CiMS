import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'login_controller.dart';

// Aquesta pantalla mostra la interfície inicial de login de l'aplicació.
// La seva responsabilitat és únicament visual: pintar el formulari,
// recollir la interacció de l'usuari i delegar les accions al controller.
// No conté lògica de negoci ni integració amb backend.
@RoutePage()
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Aquesta classe gestiona el comportament intern de la pantalla.
class _LoginScreenState extends State<LoginScreen> {
  late final LoginController controller;

  // Aquest mètode prepara el controlador quan la pantalla es carrega per primera vegada.
  @override
  void initState() {
    super.initState();
    controller = LoginController();
  }

  // Aquest mètode allibera el controlador quan la pantalla deixa d’utilitzar-se,
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

// Aquest mètode construeix la part visual de la pantalla de login.
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
                children: [ // Aquest bloc mostra el logotip a la part superior de la pantalla.
                  Align(
                    alignment: const Alignment(0, -0.72),
                    child: SvgPicture.asset(
                      'assets/images/cims_logo.svg',
                      width: 120,
                      height: 120,
                    ),
                  ),
                  AnimatedPadding(  // Aquest bloc conté tot el formulari d’inici de sessió.
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    padding: EdgeInsets.only(bottom: formBottomOffset),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [ // Aquesta targeta agrupa els camps principals del formulari
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
                                  ),
                                  const SizedBox(height: 26),
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
                                    suffixIcon: IconButton(
                                      onPressed: controller.togglePasswordVisibility,
                                      icon: Icon(
                                        controller.obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF6E6E73),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 34),
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
                                        onPressed: controller.onLoginTap,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(28),
                                          ),
                                        ),
                                        child: const Text(
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

// Aquest widget encapsula l'estil comú dels camps del formulari
// per evitar duplicació de codi i mantenir una aparença uniforme.
class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    required this.obscureText,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

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