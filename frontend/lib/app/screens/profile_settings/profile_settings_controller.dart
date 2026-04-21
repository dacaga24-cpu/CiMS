import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/entity/user.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/usecase/profile/get_user_profile_usecase.dart';
import 'package:cims/core/usecase/session/clear_session_usecase.dart';
import 'package:flutter/material.dart';

// Aquest enum representa les possibles navegacions que la pantalla pot executar.
// La vista les consumeix i fa la navegació real des de fora del controller.
enum ProfileSettingsDestination {
  none,
  back,
  login,
}

// Aquest controller gestiona la càrrega del perfil i el tancament de sessió.
// Ara la pantalla ja no depèn d’un nom manual, sinó que intenta recuperar
// el perfil real de l’usuari autenticat.
class ProfileSettingsController extends ChangeNotifier {
  ProfileSettingsController({
    Future<void> Function()? logoutAction,
    ClearSessionUseCase? clearSessionUseCase,
    GetUserProfileUseCase? getUserProfileUseCase,
  })  : _logoutAction = logoutAction,
        _clearSessionUseCase =
            clearSessionUseCase ?? AppSession.clearSessionUseCase,
        _getUserProfileUseCase =
            getUserProfileUseCase ??
                GetUserProfileUseCase(
                  apiClient: ApiClientImpl(),
                );

  // Aquest bloc agrupa les dependències principals del controller.
  // Permet carregar el perfil real de l’usuari i gestionar el tancament de sessió.
  final Future<void> Function()? _logoutAction;
  final ClearSessionUseCase _clearSessionUseCase;
  final GetUserProfileUseCase _getUserProfileUseCase;

  // Aquest bloc manté l’estat principal de la pantalla:
  // les dades del perfil, els estats de càrrega, els errors i el destí de navegació.
  User? _user;
  User? get user => _user;

  bool _isLoadingProfile = false;
  bool get isLoadingProfile => _isLoadingProfile;

  bool _isLoggingOut = false;
  bool get isLoggingOut => _isLoggingOut;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}