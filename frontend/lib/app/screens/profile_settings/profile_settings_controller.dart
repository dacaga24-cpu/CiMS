import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/user.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/usecase/profile/change_password_usecase.dart';
import 'package:cims/core/usecase/profile/delete_account_usecase.dart';
import 'package:cims/core/usecase/profile/delete_profile_photo_usecase.dart';
import 'package:cims/core/usecase/profile/get_user_profile_usecase.dart';
import 'package:cims/core/usecase/profile/update_user_profile_usecase.dart';
import 'package:cims/core/usecase/profile/upload_profile_photo_usecase.dart';
import 'package:cims/core/usecase/session/clear_session_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

// Aquest enum representa les possibles navegacions que la pantalla pot executar.
// La vista les consumeix i fa la navegació real des de fora del controller.
enum ProfileSettingsDestination {
  none,
  back,
  login,
}

// Aquest controller gestiona la càrrega del perfil, l’edició de dades personals,
// el canvi de contrasenya, la foto de perfil i el tancament de sessió.
// La pantalla només consumeix aquest estat i resol la part visual.
class ProfileSettingsController extends ChangeNotifier {
  // FlutterImageCompress interpreta minWidth/minHeight com a dimensions mínimes
  // del costat resultant. La foto de perfil es limita a una caixa de 768 px
  // perquè sigui prou nítida als avatars i carregui ràpid.
  static const int _profilePhotoMinWidth = 768;
  static const int _profilePhotoMinHeight = 768;
  static const int _profilePhotoJpegQuality = 82;
  static const String _profilePhotoMimeType = 'image/jpeg';

  ProfileSettingsController({
    Future<void> Function()? logoutAction,
    ClearSessionUseCase? clearSessionUseCase,
    GetUserProfileUseCase? getUserProfileUseCase,
    UpdateUserProfileUseCase? updateUserProfileUseCase,
    ChangePasswordUseCase? changePasswordUseCase,
    DeleteAccountUseCase? deleteAccountUseCase,
    UploadProfilePhotoUseCase? uploadProfilePhotoUseCase,
    DeleteProfilePhotoUseCase? deleteProfilePhotoUseCase,
    ImagePicker? imagePicker,
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
            changePasswordUseCase ?? ChangePasswordUseCase(ApiClientImpl()),
        _deleteAccountUseCase =
            deleteAccountUseCase ?? DeleteAccountUseCase(ApiClientImpl()),
        _uploadProfilePhotoUseCase = uploadProfilePhotoUseCase ??
            UploadProfilePhotoUseCase(ApiClientImpl()),
        _deleteProfilePhotoUseCase = deleteProfilePhotoUseCase ??
            DeleteProfilePhotoUseCase(ApiClientImpl()),
        _imagePicker = imagePicker ?? ImagePicker();

  // Aquest bloc agrupa les dependències principals del controller.
  // Permet consultar i modificar el perfil real de l’usuari autenticat.
  final Future<void> Function()? _logoutAction;
  final ClearSessionUseCase _clearSessionUseCase;
  final GetUserProfileUseCase _getUserProfileUseCase;
  final UpdateUserProfileUseCase _updateUserProfileUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;
  final DeleteAccountUseCase _deleteAccountUseCase;

  // Aquestes dependències gestionen la selecció, pujada i eliminació
  // de la foto de perfil de l’usuari autenticat.
  final UploadProfilePhotoUseCase _uploadProfilePhotoUseCase;
  final DeleteProfilePhotoUseCase _deleteProfilePhotoUseCase;
  final ImagePicker _imagePicker;

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

  // Aquest controlador guarda temporalment la contrasenya actual.
  // Es fa servir només per confirmar la desactivació del compte.
  final TextEditingController deleteAccountPasswordController =
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

  bool _isDeletingAccount = false;
  bool get isDeletingAccount => _isDeletingAccount;

  bool _isLoggingOut = false;
  bool get isLoggingOut => _isLoggingOut;

  bool _isUpdatingProfilePhoto = false;
  bool get isUpdatingProfilePhoto => _isUpdatingProfilePhoto;

  bool _showProfileValidation = false;
  bool get showProfileValidation => _showProfileValidation;

  bool _showPasswordValidation = false;
  bool get showPasswordValidation => _showPasswordValidation;

  bool _showDeleteAccountValidation = false;
  bool get showDeleteAccountValidation => _showDeleteAccountValidation;

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

  // Aquest getter retorna la foto de perfil carregada.
  // Permet que la pantalla mostri la imatge de l’usuari si existeix.
  String? get profilePhotoUrl {
    return _user?.profilePhotoUrl;
  }

  // Aquest getter indica si l’usuari té una foto de perfil associada.
  // Permet decidir si cal mostrar opcions com eliminar la foto actual.
  bool get hasProfilePhoto {
    final url = profilePhotoUrl;
    return url != null && url.isNotEmpty;
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

  // Aquest getter comprova si el formulari de desactivació té la contrasenya necessària.
  bool get isDeleteAccountFormValid {
    return deleteAccountPasswordController.text.trim().isNotEmpty;
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
      final loadedUser = await _getUserProfileUseCase.execute();

      _user = loadedUser;
      AppSession.userProfileStore.setUser(loadedUser);
      prepareProfileForm();
    } on ApiUnauthorizedException {
      await _clearSessionUseCase.execute();
      AppSession.userProfileStore.clear();
      _destination = ProfileSettingsDestination.login;
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

  // Aquest mètode notifica canvis al formulari de desactivació.
  // Permet mostrar la validació mentre l’usuari escriu la contrasenya.
  void onDeleteAccountFieldChanged() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  // Aquest mètode permet seleccionar una nova foto de perfil.
  // La imatge es prepara en format JPEG, es puja al backend i actualitza el perfil compartit.
  Future<void> changeProfilePhoto() async {
    if (_isUpdatingProfilePhoto || _isLoadingProfile) {
      return;
    }

    _errorMessage = null;
    _successMessage = null;

    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );

      if (pickedImage == null) {
        if (!_disposed) {
          notifyListeners();
        }
        return;
      }

      _isUpdatingProfilePhoto = true;

      if (!_disposed) {
        notifyListeners();
      }

      final originalBytes = await pickedImage.readAsBytes();

      final compressedBytes = await FlutterImageCompress.compressWithList(
        originalBytes,
        minWidth: _profilePhotoMinWidth,
        minHeight: _profilePhotoMinHeight,
        quality: _profilePhotoJpegQuality,
        format: CompressFormat.jpeg,
      );

      final updatedUser = await _uploadProfilePhotoUseCase(
        bytes: compressedBytes,
        mimeType: _profilePhotoMimeType,
      );

      _user = updatedUser;
      AppSession.userProfileStore.setUser(updatedUser);
      _successMessage = 'Foto de perfil actualitzada correctament';
    } on ApiUnauthorizedException {
      await _clearSessionUseCase.execute();
      AppSession.userProfileStore.clear();
      _destination = ProfileSettingsDestination.login;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      debugPrint('[ProfileSettingsController] Profile photo error: $error');
      _errorMessage = 'No s\'ha pogut actualitzar la foto de perfil';
    } finally {
      _isUpdatingProfilePhoto = false;

      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  // Aquest mètode elimina la foto de perfil actual.
  // Després actualitza el perfil local i el store compartit perquè tota la interfície canviï alhora.
  Future<void> deleteProfilePhoto() async {
    if (_isUpdatingProfilePhoto || _isLoadingProfile) {
      return;
    }

    _isUpdatingProfilePhoto = true;
    _errorMessage = null;
    _successMessage = null;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      final updatedUser = await _deleteProfilePhotoUseCase();

      _user = updatedUser;
      AppSession.userProfileStore.setUser(updatedUser);
      _successMessage = 'Foto de perfil eliminada correctament';
    } on ApiUnauthorizedException {
      await _clearSessionUseCase.execute();
      AppSession.userProfileStore.clear();
      _destination = ProfileSettingsDestination.login;
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      debugPrint(
          '[ProfileSettingsController] Delete profile photo error: $error');
      _errorMessage = 'No s\'ha pogut eliminar la foto de perfil';
    } finally {
      _isUpdatingProfilePhoto = false;

      if (!_disposed) {
        notifyListeners();
      }
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
      final updatedUser = await _updateUserProfileUseCase(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
      );

      _user = updatedUser;
      AppSession.userProfileStore.setUser(updatedUser);
      _successMessage = 'Perfil actualitzat correctament';
      _showProfileValidation = false;
      return true;
    } on ApiUnauthorizedException {
      await _clearSessionUseCase.execute();
      AppSession.userProfileStore.clear();
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
      AppSession.userProfileStore.clear();
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

  // Aquest mètode envia al backend la petició de desactivació del compte.
  // Si la contrasenya és correcta, neteja la sessió i envia l’usuari al login.
  Future<bool> deleteAccount() async {
    if (_isDeletingAccount) return false;

    _showDeleteAccountValidation = true;
    _errorMessage = null;
    _successMessage = null;

    if (!isDeleteAccountFormValid) {
      notifyListeners();
      return false;
    }

    _isDeletingAccount = true;

    if (!_disposed) {
      notifyListeners();
    }

    try {
      await _deleteAccountUseCase(
        password: deleteAccountPasswordController.text.trim(),
      );

      clearDeleteAccountForm();
      await _clearSessionUseCase.execute();
      AppSession.userProfileStore.clear();
      _successMessage = 'Compte desactivat correctament';
      _destination = ProfileSettingsDestination.login;
      return true;
    } on ApiUnauthorizedException {
      await _clearSessionUseCase.execute();
      AppSession.userProfileStore.clear();
      _destination = ProfileSettingsDestination.login;
      return false;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'No s\'ha pogut desactivar el compte';
      return false;
    } finally {
      _isDeletingAccount = false;

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

  // Aquest mètode neteja el formulari de desactivació.
  // Evita conservar la contrasenya després de tancar el formulari.
  void clearDeleteAccountForm() {
    deleteAccountPasswordController.clear();
    _showDeleteAccountValidation = false;
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
      AppSession.userProfileStore.clear();
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
    deleteAccountPasswordController.dispose();
    super.dispose();
  }
}
