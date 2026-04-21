import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/usecase/auth/login_usecase.dart';
import 'package:cims/core/usecase/auth/request_password_reset_usecase.dart';
import 'package:cims/core/usecase/session/save_session_usecase.dart';
import 'package:flutter/material.dart';

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
  LoginController({
    LoginUseCase? loginUseCase,
    RequestPasswordResetUseCase? requestPasswordResetUseCase,
    SaveSessionUseCase? saveSessionUseCase,
  })  : _loginUseCase = loginUseCase ??
            LoginUseCase(
              apiClient: ApiClientImpl(),
            ),
        _requestPasswordResetUseCase = requestPasswordResetUseCase ??
            RequestPasswordResetUseCase(
              apiClient: ApiClientImpl(),
            ),
        _saveSessionUseCase =
            saveSessionUseCase ?? AppSession.saveSessionUseCase;

  // Aquest bloc agrupa els casos d’ús principals del login i de recuperació de contrasenya,
  // juntament amb els controladors de text del formulari.
  final LoginUseCase _loginUseCase;
  final RequestPasswordResetUseCase _requestPasswordResetUseCase;
  final SaveSessionUseCase _saveSessionUseCase;

  // Aquests controladors conserven el text que escriu l’usuari
  // als dos camps principals del formulari.
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Aquest bloc manté l’estat general de la pantalla.
  // Aquí es controla si la contrasenya es mostra o s’oculta, si hi ha una petició en curs,
  // si s’han d’ensenyar validacions i quin és el següent destí de navegació.
  bool obscurePassword = true;
  bool showValidation = false;
  bool isLoading = false;
  String? errorMessage;
  String? infoMessage;

  // Aquest indicador evita actualitzacions d’estat quan el controlador
  // ja ha estat tancat i la pantalla no està activa.
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
  // La seva funció és netejar missatges previs i avisar la interfície perquè es refresqui.
  void onEmailChanged(String value) {
    errorMessage = null;
    infoMessage = null;
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
  // i finalment delega l’operació d’autenticació al cas d’ús corresponent.
  // Si tot va bé, prepara l’entrada al dashboard; si falla, guarda un missatge d’error.
  Future<void> onLoginTap() async {
    if (isLoading) return;

    showValidation = true;
    errorMessage = null;
    infoMessage = null;
    notifyListeners();

    if (!canSubmit) return;

    // Aquest bloc marca que hi ha una operació en curs
    // perquè la vista pugui bloquejar noves interaccions mentre espera resposta.
    isLoading = true;
    notifyListeners();

    try {
      final loginResponse = await _loginUseCase.execute(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Si el login és correcte, es desa la sessió local
      // perquè l’usuari pugui continuar autenticat dins de l’aplicació.
      await _saveSessionUseCase.execute(
        token: loginResponse.token,
        userId: loginResponse.userId,
      );

      _destination = LoginNavigationDestination.dashboard;
    } on ApiException catch (error) {
      // Aquest bloc transforma els errors tècnics més habituals
      // en missatges més clars i útils per a l’usuari.
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

  // Aquest mètode aprofita el correu ja escrit al formulari per iniciar
  // el procés de recuperació de contrasenya sense sortir de la pantalla de login.
  Future<void> onForgotPasswordTap() async {
    if (isLoading) return;

    showValidation = true;
    errorMessage = null;
    infoMessage = null;
    notifyListeners();

    final email = emailController.text.trim();

    if (email.isEmpty || !_isValidEmail(email)) {
      errorMessage = 'Has d’introduir un correu vàlid';
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      await _requestPasswordResetUseCase.execute(
        email: email,
      );

      infoMessage =
          'Si el correu existeix, t’hem enviat un enllaç per restablir la contrasenya';
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'No s\'ha pogut processar la recuperació de contrasenya';
    } finally {
      isLoading = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

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
