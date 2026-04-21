import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/usecase/auth/register_usecase.dart';
import 'package:flutter/material.dart';

// Aquest bloc defineix els possibles destins de navegació de la pantalla de registre.
// Serveix per indicar si l’usuari ha de tornar al login o obrir la pantalla de termes.
enum RegisterNavigationDestination {
  none,
  login,
  terms,
}

// Aquest controlador gestiona el comportament funcional de la pantalla de registre.
// S’encarrega de controlar els camps del formulari, validar les dades,
// comunicar-se amb l’API i indicar a la vista què ha de mostrar o cap on ha de navegar.
class RegisterController extends ChangeNotifier {
  // El controlador pot rebre el cas d’ús del registre des de fora o crear-ne un per defecte.
  // Això permet desacoblar el flux de registre de la pantalla
  // i facilita una arquitectura més neta.
  RegisterController({
    RegisterUseCase? registerUseCase,
  }) : _registerUseCase = registerUseCase ??
            RegisterUseCase(
              apiClient: ApiClientImpl(),
            );

  // Aquest bloc agrupa el cas d’ús del registre i els controladors de text del formulari.
  // Gràcies a això es poden llegir i gestionar les dades que l’usuari escriu a cada camp.
  final RegisterUseCase _registerUseCase;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Aquest bloc manté l’estat general de la pantalla.
  // Aquí es controla si la contrasenya es mostra o s’oculta, si hi ha una petició en curs,
  // si s’han d’ensenyar validacions i quin és el següent destí de navegació.
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool showValidation = false;
  bool isLoading = false;
  String? errorMessage;

  RegisterNavigationDestination _destination =
      RegisterNavigationDestination.none;
  RegisterNavigationDestination get destination => _destination;

  // Aquests getters resumeixen les validacions principals del formulari.
  // Són rellevants perquè permeten a la vista saber si hi ha errors,
  // si les contrasenyes coincideixen i si el formulari ja es pot enviar.
  bool get passwordsMatch =>
      passwordController.text == confirmPasswordController.text;

  bool get hasPasswordMismatch =>
      passwordController.text.isNotEmpty &&
      confirmPasswordController.text.isNotEmpty &&
      !passwordsMatch;

  bool get canSubmit =>
      firstNameController.text.trim().isNotEmpty &&
      lastNameController.text.trim().isNotEmpty &&
      emailController.text.trim().isNotEmpty &&
      passwordController.text.isNotEmpty &&
      confirmPasswordController.text.isNotEmpty &&
      passwordsMatch &&
      _isValidEmail(emailController.text.trim()) &&
      passwordController.text.length >= 8;

  // Aquests indicadors permeten mostrar a la interfície quins camps obligatoris
  // encara no s’han omplert després d’intentar enviar el formulari.
  bool get hasEmptyFirstName =>
      showValidation && firstNameController.text.trim().isEmpty;

  bool get hasEmptyLastName =>
      showValidation && lastNameController.text.trim().isEmpty;

  bool get hasEmptyEmail =>
      showValidation && emailController.text.trim().isEmpty;

  bool get hasEmptyPassword =>
      showValidation && passwordController.text.isEmpty;

  bool get hasEmptyConfirmPassword =>
      showValidation && confirmPasswordController.text.isEmpty;

  // Aquests indicadors controlen els errors de format més importants del formulari,
  // com ara un correu no vàlid o una contrasenya massa curta.
  bool get hasInvalidEmail =>
      showValidation &&
      emailController.text.trim().isNotEmpty &&
      !_isValidEmail(emailController.text.trim());

  bool get hasShortPassword =>
      showValidation &&
      passwordController.text.isNotEmpty &&
      passwordController.text.length < 8;

  // Aquests mètodes responen als canvis que fa l’usuari als camps del formulari.
  // La seva funció és netejar errors previs i avisar la interfície perquè es refresqui.
  void onFirstNameChanged(String value) {
    errorMessage = null;
    notifyListeners();
  }

  void onLastNameChanged(String value) {
    errorMessage = null;
    notifyListeners();
  }

  void onEmailChanged(String value) {
    errorMessage = null;
    notifyListeners();
  }

  void onPasswordChanged(String value) {
    errorMessage = null;
    notifyListeners();
  }

  void onConfirmPasswordChanged(String value) {
    errorMessage = null;
    notifyListeners();
  }

  // Aquests mètodes permeten mostrar o ocultar la contrasenya.
  // Són útils per millorar la comoditat de l’usuari mentre escriu.
  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword = !obscureConfirmPassword;
    notifyListeners();
  }

  // Aquest mètode gestiona l’acció principal de crear un compte.
  // Primer activa les validacions, després comprova si el formulari és correcte
  // i finalment delega l’operació de registre al cas d’ús corresponent.
  // Si el registre va bé, prepara la navegació al login; si falla, guarda un missatge d’error.
  Future<void> onCreateAccountTap() async {
    if (isLoading) return;

    showValidation = true;
    errorMessage = null;
    notifyListeners();

    if (!canSubmit) return;

    // Aquest bloc marca que el procés de registre està en curs
    // perquè la vista pugui bloquejar noves interaccions mentre espera la resposta.
    isLoading = true;
    notifyListeners();

    try {
      await _registerUseCase.execute(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      _destination = RegisterNavigationDestination.login;
    } on ApiException catch (error) {
      // Aquest bloc transforma els errors més rellevants del backend
      // en missatges més clars per a l’usuari final.
      if (error.statusCode == 409) {
        errorMessage = 'Aquest correu ja està registrat';
      } else {
        errorMessage = error.message;
      }
    } catch (_) {
      errorMessage = 'No s\'ha pogut completar el registre';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Aquest mètode envia l’usuari a la pantalla d’inici de sessió
  // quan ja té un compte creat.
  void onAlreadyHaveAccountTap() {
    _destination = RegisterNavigationDestination.login;
    notifyListeners();
  }

  // Aquest mètode prepara la navegació cap a la pantalla de termes del servei.
  void onTermsTap() {
    _destination = RegisterNavigationDestination.terms;
    notifyListeners();
  }

  // Aquest mètode reinicia el destí de navegació després que la vista ja l’hagi consumit.
  // Això evita repetir la mateixa redirecció més d’una vegada.
  void consumeNavigation() {
    _destination = RegisterNavigationDestination.none;
  }

  // Aquest mètode comprova de manera bàsica si el correu escrit té un format vàlid.
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  // Aquest mètode allibera els recursos associats als camps del formulari
  // quan el controlador deixa d’utilitzar-se.
  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}