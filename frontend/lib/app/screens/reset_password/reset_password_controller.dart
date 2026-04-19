import 'package:flutter/material.dart';

// Aquest bloc defineix els possibles destins de navegació de la pantalla.
// Serveix per indicar si l’usuari ha de tornar a l’inici de sessió.
enum ResetPasswordNavigationDestination {
  none,
  login,
}

// Aquest controlador gestiona el comportament funcional de la pantalla
// de nova contrasenya. S’encarrega de controlar els camps del formulari,
// validar les dades i indicar a la vista què ha de mostrar o cap on ha de navegar.
class ResetPasswordController extends ChangeNotifier {
  // Aquest bloc agrupa els controladors de text del formulari.
  // Gràcies a això es poden llegir i gestionar les dades
  // que l’usuari escriu als dos camps de contrasenya.
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Aquest bloc manté l’estat general de la pantalla.
  // Aquí es controla si les contrasenyes es mostren o s’oculten,
  // si s’han d’ensenyar validacions, si hi ha una operació en curs
  // i quin és el següent destí de navegació.
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool showValidation = false;
  bool isLoading = false;
  String? errorMessage;

  ResetPasswordNavigationDestination _destination =
      ResetPasswordNavigationDestination.none;
  ResetPasswordNavigationDestination get destination => _destination;

  // Aquests getters resumeixen les validacions principals del formulari.
  // Són rellevants perquè permeten a la vista saber si hi ha errors,
  // si les dues contrasenyes coincideixen i si el formulari és correcte.
  bool get passwordsMatch =>
      passwordController.text == confirmPasswordController.text;

  bool get hasPasswordMismatch =>
      showValidation &&
      passwordController.text.isNotEmpty &&
      confirmPasswordController.text.isNotEmpty &&
      !passwordsMatch;

  bool get canSubmit =>
      passwordController.text.isNotEmpty &&
      confirmPasswordController.text.isNotEmpty &&
      passwordController.text.length >= 8 &&
      passwordsMatch;

  // Aquests indicadors permeten mostrar a la interfície quins camps obligatoris
  // encara no s’han omplert després d’intentar continuar.
  bool get hasEmptyPassword =>
      showValidation && passwordController.text.isEmpty;

  bool get hasEmptyConfirmPassword =>
      showValidation && confirmPasswordController.text.isEmpty;

  // Aquest indicador controla si la nova contrasenya encara no compleix
  // la longitud mínima definida per al formulari.
  bool get hasShortPassword =>
      showValidation &&
      passwordController.text.isNotEmpty &&
      passwordController.text.length < 8;

  // Aquests mètodes responen als canvis que fa l’usuari als camps del formulari.
  // La seva funció és netejar errors previs i avisar la interfície perquè es refresqui.
  void onPasswordChanged(String value) {
    errorMessage = null;
    notifyListeners();
  }

  void onConfirmPasswordChanged(String value) {
    errorMessage = null;
    notifyListeners();
  }

  // Aquests mètodes permeten mostrar o ocultar cada contrasenya.
  // Són útils per millorar la comoditat de l’usuari mentre escriu.
  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    notifyListeners();
  }

  // Aquest mètode gestiona l’acció principal del formulari.
  // En aquesta primera versió s’encarrega només d’activar les validacions
  // i comprovar si les dades mínimes són correctes. La connexió amb el backend
  // quedarà preparada per a la tasca d’integració.
  Future<void> onChangePasswordTap() async {
    if (isLoading) return;

    showValidation = true;
    errorMessage = null;
    notifyListeners();

    if (!canSubmit) return;

    // Aquesta pantalla queda preparada visualment i funcionalment a nivell local.
    // La lògica real de canvi de contrasenya es connectarà més endavant
    // amb el cas d’ús i l’API corresponents.
  }

  // Aquest mètode prepara la navegació de tornada a l’inici de sessió.
  void onBackToLoginTap() {
    _destination = ResetPasswordNavigationDestination.login;
    notifyListeners();
  }

  // Aquest mètode reinicia el destí de navegació després que la vista ja l’hagi consumit.
  // Això evita repetir la mateixa redirecció més d’una vegada.
  void consumeNavigation() {
    _destination = ResetPasswordNavigationDestination.none;
  }

  // Aquest mètode allibera els recursos associats als camps del formulari
  // quan el controlador deixa d’utilitzar-se.
  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}