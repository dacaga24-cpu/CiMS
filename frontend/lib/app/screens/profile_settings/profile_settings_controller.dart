import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/user.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/usecase/profile/change_password_usecase.dart';
import 'package:cims/core/usecase/profile/get_user_profile_usecase.dart';
import 'package:cims/core/usecase/session/clear_session_usecase.dart';
import 'package:cims/core/usecase/profile/update_user_profile_usecase.dart';
import 'package:flutter/material.dart';

// Aquest enum representa les possibles navegacions que la pantalla pot executar.
// La vista les consumeix i fa la navegació real des de fora del controller.
enum ProfileSettingsDestination {
  none,
  back,
  login,
}

// Aquest controller gestiona la càrrega del perfil, l’edició de dades personals,
// el canvi de contrasenya i el tancament de sessió.
// La pantalla només consumeix aquest estat i resol la part visual.
class ProfileSettingsController extends ChangeNotifier {
  ProfileSettingsController({
    Future<void> Function()? logoutAction,
    ClearSessionUseCase? clearSessionUseCase,
    GetUserProfileUseCase? getUserProfileUseCase,
    UpdateUserProfileUseCase? updateUserProfileUseCase,
    ChangePasswordUseCase? changePasswordUseCase,
  })  : _logoutAction = logoutAction,
        _clearSessionUseCase =
            clearSessionUseCase ?? AppSession.clearSessionUseCase,
        _getUserProfileUseCase = getUserProfileUseCase ??
            GetUserProfileUseCase(
              apiClient: ApiClientImpl(),
            ),
        _updateUserProfileUseCase = updateUserProfileUseCase ??
            UpdateUserProfileUseCase(ApiClientImpl()),
        _changePasswordUseCase =
            changePasswordUseCase ?? ChangePasswordUseCase(ApiClientImpl());

  // Aquest bloc agrupa les dependències principals del controller.
  // Permet consultar i modificar el perfil real de l’usuari autenticat.
  final Future<void> Function()? _logoutAction;
  final ClearSessionUseCase _clearSessionUseCase;
  final GetUserProfileUseCase _getUserProfileUseCase;
  final UpdateUserProfileUseCase _updateUserProfileUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;

  // Aquests controladors guarden temporalment les dades del formulari de perfil.
  // La pantalla els utilitza per editar el nom i cognoms sense gestionar lògica.
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  // Aquests controladors guarden temporalment les dades del formulari de contrasenya.
  // Permeten validar i enviar el canvi de contrasenya des del controller.
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Aquest bloc manté l’estat principal de la pantalla:
  // les dades del perfil, els estats de càrrega, els errors i el destí de navegació.
  User? _user;
  User? get user => _user;

  bool _isLoadingProfile = false;
  bool get isLoadingProfile => _isLoadingProfile;

  bool _isSavingProfile = false;
  bool get isSavingProfile => _isSavingProfile;

  bool _isChangingPassword = false;
  bool get isChangingPassword => _isChangingPassword;

  bool _isLoggingOut = false;
  bool get isLoggingOut => _isLoggingOut;

  bool _showProfileValidation = false;
  bool get showProfileValidation => _showProfileValidation;

  bool _showPasswordValidation = false;
  bool get showPasswordValidation => _showPasswordValidation;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  bool _disposed = false;

  ProfileSettingsDestination _destination = ProfileSettingsDestination.none;
  ProfileSettingsDestination get destination => _destination;

  // Aquest getter construeix el nom que es mostrarà a la pantalla.
  // Si encara no s’ha pogut carregar el perfil, retorna un text genèric.
  String get displayName {
    final currentUser = _user;
    if (currentUser == null) {
      return 'Usuari';
    }

    return '${currentUser.firstName} ${currentUser.lastName}'.trim();
  }

  // Aquest getter retorna el correu del perfil carregat.
  // És útil per mostrar informació bàsica del compte sense duplicar lògica a la pantalla.
  String get displayEmail {
    return _user?.email ?? '';
  }

  // Aquest getter indica si el formulari de perfil té les dades mínimes necessàries.
  bool get isProfileFormValid {
    return firstNameController.text.trim().isNotEmpty &&
        lastNameController.text.trim().isNotEmpty;
  }

  // Aquest getter indica si el formulari de contrasenya pot enviar-se al backend.
  bool get isPasswordFormValid {
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    return currentPassword.isNotEmpty &&
        newPassword.length >= 8 &&
        newPassword == confirmPassword;
  }

  // Aquest mètode carrega les dades del perfil autenticat.
  // També actualitza l’estat visual perquè la pantalla pugui mostrar càrrega o errors.
  Future<void> loadProfile() async {
    if (_isLoadingProfile) return;

    _isLoadingProfile = true;
    _errorMessage = null;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      _user = await _getUserProfileUseCase.execute();
      prepareProfileForm();
    } on ApiUnauthorizedException {
      // En aquest cas no mostrem error manual perquè la sessió ja es neteja
      // i la redirecció global a login es resol des de la sessió centralitzada.
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No s\'ha pogut carregar el perfil';
    } finally {
      _isLoadingProfile = false;

      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  // Aquest mètode copia les dades actuals de l’usuari al formulari d’edició.
  // Serveix per obrir el formulari amb la informació real ja carregada.
  void prepareProfileForm() {
    final currentUser = _user;
    if (currentUser == null) return;

    firstNameController.text = currentUser.firstName;
    lastNameController.text = currentUser.lastName;
    _showProfileValidation = false;
  }

  // Aquest mètode notifica canvis en el formulari de perfil.
  // Permet que la pantalla actualitzi possibles validacions mentre l’usuari escriu.
  void onProfileFieldChanged() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // Aquest mètode notifica canvis en el formulari de contrasenya.
  // Permet validar coincidència i longitud abans d’enviar les dades.
  void onPasswordFieldChanged() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // Aquest mètode envia al backend les dades actualitzades del perfil.
  // Si l’operació és correcta, actualitza l’usuari local i mostra un missatge de confirmació.
  Future<bool> saveProfileChanges() async {
    if (_isSavingProfile) return false;

    _showProfileValidation = true;
    _errorMessage = null;
    _successMessage = null;

    if (!isProfileFormValid) {
      notifyListeners();
      return false;
    }

    _isSavingProfile = true;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      _user = await _updateUserProfileUseCase(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
      );

      _successMessage = 'Perfil actualitzat correctament';
      _showProfileValidation = false;
      return true;
    } on ApiUnauthorizedException {
      await _clearSessionUseCase.execute();
      _destination = ProfileSettingsDestination.login;
      return false;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'No s\'ha pogut actualitzar el perfil';
      return false;
    } finally {
      _isSavingProfile = false;

      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  // Aquest mètode envia al backend el canvi de contrasenya.
  // Després d’una resposta correcta, neteja el formulari per evitar conservar dades sensibles.
  Future<bool> changePassword() async {
    if (_isChangingPassword) return false;

    _showPasswordValidation = true;
    _errorMessage = null;
    _successMessage = null;

    if (!isPasswordFormValid) {
      notifyListeners();
      return false;
    }

    _isChangingPassword = true;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      await _changePasswordUseCase(
        currentPassword: currentPasswordController.text.trim(),
        newPassword: newPasswordController.text.trim(),
      );

      clearPasswordForm();
      _successMessage = 'Contrasenya actualitzada correctament';
      return true;
    } on ApiUnauthorizedException {
      await _clearSessionUseCase.execute();
      _destination = ProfileSettingsDestination.login;
      return false;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'No s\'ha pogut canviar la contrasenya';
      return false;
    } finally {
      _isChangingPassword = false;

      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  // Aquest mètode neteja els camps del formulari de contrasenya.
  // És important per no mantenir dades sensibles a la pantalla després de l’operació.
  void clearPasswordForm() {
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    _showPasswordValidation = false;
  }

  // Aquest mètode prepara el retorn a la pantalla anterior.
  void onBackTap() {
    _destination = ProfileSettingsDestination.back;
    notifyListeners();
  }

  // Aquest mètode gestiona el procés de tancar sessió.
  // Primer executa l’acció de logout si existeix, després neteja la sessió local
  // i finalment indica a la vista que ha de navegar al login.
  Future<void> onLogoutTap() async {
    if (_isLoggingOut) return;

    _isLoggingOut = true;
    _errorMessage = null;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      if (_logoutAction != null) {
        await _logoutAction!();
      }

      await _clearSessionUseCase.execute();
      _destination = ProfileSettingsDestination.login;
    } catch (_) {
      _errorMessage = 'No s\'ha pogut tancar la sessió';
    } finally {
      _isLoggingOut = false;

      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  // Aquest mètode reinicia el destí de navegació
  // després que la vista ja l’hagi consumit.
  void consumeNavigation() {
    _destination = ProfileSettingsDestination.none;
  }

  // Aquest mètode permet netejar el missatge d’error actual
  // quan la vista ja l’ha mostrat o ja no és necessari.
  void consumeErrorMessage() {
    _errorMessage = null;
  }

  // Aquest mètode permet netejar el missatge de confirmació
  // després que la vista ja l’hagi mostrat a l’usuari.
  void consumeSuccessMessage() {
    _successMessage = null;
  }

  @override
  void dispose() {
    _disposed = true;
    firstNameController.dispose();
    lastNameController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
