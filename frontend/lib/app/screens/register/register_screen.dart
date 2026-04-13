import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'register_controller.dart';

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
    controller = RegisterController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: [
                  Align(
                    alignment: const Alignment(0, -0.72),
                    child: SvgPicture.asset(
                      'assets/images/cims_logo.svg',
                      width: 92,
                      height: 92,
                    ),
                  ),
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
                                    hintText: 'Correu',
                                    keyboardType: TextInputType.emailAddress,
                                    obscureText: false,
                                    onChanged: controller.onEmailChanged,
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Contrasenya',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _InputField(
                                    controller: controller.passwordController,
                                    hintText: '••••••••••••',
                                    keyboardType: TextInputType.text,
                                    obscureText: controller.obscurePassword,
                                    onChanged: controller.onPasswordChanged,
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
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Confirmar Contrasenya',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _InputField(
                                    controller:
                                        controller.confirmPasswordController,
                                    hintText: '••••••••••••',
                                    keyboardType: TextInputType.text,
                                    obscureText:
                                        controller.obscureConfirmPassword,
                                    onChanged:
                                        controller.onConfirmPasswordChanged,
                                    suffixIcon: IconButton(
                                      onPressed: controller
                                          .toggleConfirmPasswordVisibility,
                                      icon: Icon(
                                        controller.obscureConfirmPassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF6E6E73),
                                      ),
                                    ),
                                  ),
                                  if (controller.hasPasswordMismatch) ...[
                                    const SizedBox(height: 10),
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 16,
                                          color: Color(0xFFD93025),
                                        ),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'Les contrasenyes han de coincidir',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFFD93025),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 28),
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
                                        onPressed: controller.onCreateAccountTap,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(28),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Crear compte',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: controller.onAlreadyHaveAccountTap,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFD9D9D9),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                        ),
                                      ),
                                      child: const Text(
                                        'Ja tinc un compte',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0B57D0),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  const Text(
                                    'En registrar-te, acceptes els nostres ',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF3C3C43),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: controller.onTermsTap,
                                    child: const Text(
                                      'Termes de Servei',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0B57D0),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    required this.obscureText,
    required this.onChanged,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final ValueChanged<String> onChanged;
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
        onChanged: onChanged,
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