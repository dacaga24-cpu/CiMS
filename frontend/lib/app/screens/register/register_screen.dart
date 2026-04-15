import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../router/app_router.dart';

import 'register_controller.dart';

// Aquesta pantalla mostra el formulari de registre de l’aplicació.
// La seva funció és recollir les dades bàsiques per crear un compte nou
// i connectar la interfície amb la lògica que valida i gestiona el procés de registre.
@RoutePage()
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// Aquesta classe gestiona el comportament intern de la pantalla.
// Aquí es crea el controlador, es mantenen actualitzats els canvis del formulari
// i es construeix tota la interfície que veu l’usuari.
class _RegisterScreenState extends State<RegisterScreen> {
  late final RegisterController controller;

  @override
  // Aquest mètode prepara el controlador quan la pantalla es carrega per primera vegada.
  void initState() {
    super.initState();
    controller = RegisterController()..addListener(_handleControllerChanges);
  }

  // Aquest mètode escolta els canvis del controlador i actua quan cal navegar
  // a una altra pantalla o mostrar una acció puntual relacionada amb el registre.
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
        builder: (context) => AlertDialog(
          title: const Text('Termes de Servei'),
          content: const Text(
            'Aquesta funcionalitat encara no està implementada.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('D\'acord'),
            ),
          ],
        ),
      );
    }
  }

  @override
  // Aquest mètode allibera el controlador quan la pantalla deixa d’utilitzar-se.
  void dispose() {
    controller.removeListener(_handleControllerChanges);
    controller.dispose();
    super.dispose();
  }

  @override
  // Aquest mètode construeix la part visual de la pantalla de registre.
  // També ajusta la posició del formulari quan apareix el teclat,
  // perquè els camps continuïn sent accessibles mentre l’usuari escriu.
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
                  // Aquest bloc conté el formulari principal i el desplaça quan apareix el teclat.
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
                            // Aquesta targeta agrupa els camps necessaris per crear el compte i els botons principals relacionats amb el registre.
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
                                    'Nom',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _InputField(
                                    controller: controller.firstNameController,
                                    hintText: 'Nom',
                                    keyboardType: TextInputType.name,
                                    obscureText: false,
                                    onChanged: controller.onFirstNameChanged,
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Cognom',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _InputField(
                                    controller: controller.lastNameController,
                                    hintText: 'Cognom',
                                    keyboardType: TextInputType.name,
                                    obscureText: false,
                                    onChanged: controller.onLastNameChanged,
                                  ),
                                  const SizedBox(height: 24),
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
                                  if (controller.hasInvalidEmail) ...[
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Introdueix un correu electrònic vàlid',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFD93025),
                                      ),
                                    ),
                                  ],
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
                                      onPressed:
                                          controller.togglePasswordVisibility,
                                      icon: Icon(
                                        controller.obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: const Color(0xFF6E6E73),
                                      ),
                                    ),
                                  ),
                                  if (controller.hasShortPassword) ...[
                                    const SizedBox(height: 10),
                                    const Text(
                                      'La contrasenya ha de tenir almenys 8 caràcters',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFD93025),
                                      ),
                                    ),
                                  ],
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
                                    // Aquest missatge només es mostra quan les dues contrasenyes no coincideixen.
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
                                  if (controller.errorMessage != null) ...[
                                    const SizedBox(height: 14),
                                    Text(
                                      controller.errorMessage!,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFFD93025),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 28),
                                  SizedBox(
                                    // Aquest botó inicia el procés de creació del compte amb les dades que l’usuari ha introduït al formulari.
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
                                            : controller.onCreateAccountTap,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(28),
                                          ),
                                        ),
                                        child: controller.isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.4,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Crear compte',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                    // Aquest botó permet tornar al flux d’accés per a usuaris que ja disposen d’un compte i no necessiten registrar-se.
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed:
                                          controller.onAlreadyHaveAccountTap,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFFD9D9D9),
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
                              // Aquest bloc informa l’usuari que el registre implica l’acceptació de les condicions bàsiques del servei.
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
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

// Aquest component reutilitzable representa un camp de text amb el mateix estil visual.
// Serveix per mantenir coherència entre els camps del formulari i evitar repetir codi.
class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    required this.obscureText,
    required this.onChanged,
    this.suffixIcon,
  });

  // Aquest bloc defineix la informació necessària per configurar el camp:
  // el text introduït, l’ajuda visual, el tipus d’entrada,
  // si el contingut s’ha d’ocultar i l’acció a executar quan canvia.
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final ValueChanged<String> onChanged;
  final Widget? suffixIcon;

  @override
  // Aquest mètode construeix visualment el camp de text amb l’estil comú del formulari.
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