// lib/app/screens/main_navigation/main_navigation_controller.dart

import 'package:cims/app/client/api/api_client_impl.dart';
import 'package:cims/core/client/api_client.dart';
import 'package:cims/core/session/app_session.dart';
import 'package:cims/core/usecase/profile/get_user_profile_usecase.dart';
import 'package:flutter/material.dart';

// Aquest controller prepara les dades compartides de la navegació principal.
// Carrega el perfil de l’usuari perquè la capçalera pugui mostrar la foto actual.
class MainNavigationController extends ChangeNotifier {
  MainNavigationController({
    GetUserProfileUseCase? getUserProfileUseCase,
  }) : _getUserProfileUseCase = getUserProfileUseCase ??
            GetUserProfileUseCase(
              apiClient: ApiClientImpl(),
            );

  final GetUserProfileUseCase _getUserProfileUseCase;

  bool _isLoadingProfile = false;
  bool _disposed = false;

  // Aquest mètode carrega el perfil només si encara no està disponible.
  // Això evita repetir peticions i manté la foto sincronitzada al store compartit.
  Future<void> loadUserProfileIfNeeded() async {
    if (_isLoadingProfile) return;
    if (AppSession.userProfileStore.user != null) return;

    _isLoadingProfile = true;

    try {
      final user = await _getUserProfileUseCase.execute();
      AppSession.userProfileStore.setUser(user);
    } on ApiUnauthorizedException {
      await AppSession.handleUnauthorized();
    } catch (error) {
      debugPrint('[MainNavigationController] Profile load error: $error');
    } finally {
      _isLoadingProfile = false;

      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}