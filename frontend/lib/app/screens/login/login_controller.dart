import 'package:flutter/material.dart';

import '../../../core/client/api_client.dart';
import '../../client/api/api_client_impl.dart';

// Aquest bloc defineix els possibles destins de navegació després d’interactuar
// amb la pantalla de login. Serveix per indicar si l’usuari ha d’anar
// al registre o entrar a la part principal de l’aplicació.
enum LoginNavigationDestination {
  none,
  register,
  dashboard,
}

// Aquest controlador gestiona el comportament funcional de la pantalla de login.
// S’encarrega de controlar els camps del formulari, validar les dades,
// comunicar-se amb el backend i indicar a la vista què ha de mostrar o cap on ha de navegar.
class LoginController extends ChangeNotifier {
  // El controlador pot rebre un client d’API extern o crear-ne un per defecte.
  // Això permet reutilitzar la mateixa lògica en diferents contextos, com ara proves o execució normal.
  LoginController({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClientImpl();

  // Aquest bloc agrupa la connexió amb l’API i els controladors de text del formulari.
  // Gràcies a això, el controlador pot llegir i gestionar les dades que l’usuari escriu.
  final ApiClient _apiClient;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Aquest bloc manté l’estat general de la pantalla.
  // Aquí es controla si la contrasenya es mostra o s’oculta, si hi ha una petició en curs,
  // si s’han d’ensenyar validacions i quin és el següent destí de navegació.
  bool obscurePassword = true;
  bool showValidation = false;
  bool isLoading = false;
  String? errorMessage;

  bool _disposed = false;

  LoginNavigationDestination _destination = LoginNavigationDestination.none;
  LoginNavigationDestination get destination => _destination;

  // Aquests getters resumeixen les validacions principals del formulari.
  // Són útils perquè la vista pugui saber si cal mostrar errors
  // i si ja es pot intentar l’inici de sessió.
  bool get hasInvalidEmail =>
      showValidation &&
      emailController.text.trim().isNotEmpty &&
      !_isValidEmail(emailController.text.trim());

  bool get hasEmptyPassword =>
      showValidation && passwordController.text.isEmpty;

  bool get canSubmit =>
      emailController.text.trim().isNotEmpty &&
      passwordController.text.isNotEmpty &&
      _isValidEmail(emailController.text.trim());

  // Aquests mètodes responen als canvis que l’usuari fa als camps del formulari.
  // La seva funció és netejar errors previs i avisar la interfície perquè es refresqui.
  void onEmailChanged(String value) {
    errorMessage = null;
    notifyListeners();
  }

  void onPasswordChanged(String value) {
    errorMessage = null;
    notifyListeners();
  }

  // Aquest mètode permet mostrar o ocultar la contrasenya.
  // És útil per millorar la comoditat de l’usuari mentre escriu.
  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  // Aquest mètode gestiona l’acció principal d’iniciar sessió.
  // Primer activa les validacions, després comprova si el formulari és correcte
  // i finalment envia les credencials al backend. Si tot va bé, prepara l’entrada al dashboard;
  // si falla, guarda un missatge d’error perquè la vista el pugui mostrar.
  Future<void> onLoginTap() async {
    if (isLoading) return;

    showValidation = true;
    errorMessage = null;
    notifyListeners();

    if (!canSubmit) return;

    isLoading = true;
    notifyListeners();

    try {
      await _apiClient.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      _destination = LoginNavigationDestination.dashboard;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        errorMessage = 'Credencials incorrectes';
      } else if (error.statusCode == 400) {
        errorMessage = 'Revisa les dades introduïdes';
      } else {
        errorMessage = error.message;
      }
    } catch (_) {
      errorMessage = 'No s\'ha pogut iniciar sessió';
    } finally {
      isLoading = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  // Aquest mètode queda reservat per al futur flux de recuperació de contrasenya.
  void onForgotPasswordTap() {}

  // Aquest mètode prepara la navegació cap a la pantalla de registre.
  void onRegisterTap() {
    _destination = LoginNavigationDestination.register;
    notifyListeners();
  }

  // Aquest mètode reinicia el destí de navegació després que la vista ja l’hagi utilitzat.
  // Això evita repetir la mateixa redirecció més d’una vegada.
  void consumeNavigation() {
    _destination = LoginNavigationDestination.none;
  }

  // Aquest mètode comprova de manera bàsica si el correu escrit té un format vàlid.
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  // Aquest mètode allibera els recursos associats als camps del formulari
  // i marca el controlador com a finalitzat per evitar actualitzacions fora de temps.
  @override
  void dispose() {
    _disposed = true;
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
