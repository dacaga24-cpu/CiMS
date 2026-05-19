import 'package:auto_route/auto_route.dart';
import 'package:cims/app/router/app_router.dart';
import 'package:flutter/material.dart';
import 'profile_settings_controller.dart';
import 'widgets/profile_edit_form.dart';
import 'widgets/profile_password_form.dart';
import 'widgets/profile_settings_header.dart';
import 'widgets/profile_settings_logout_button.dart';
import 'widgets/profile_settings_options_card.dart';
import 'widgets/profile_settings_section_title.dart';
import 'widgets/profile_settings_top_bar.dart';
import 'widgets/profile_delete_account_form.dart';
import 'widgets/profile_photo_actions_sheet.dart';

// Aquesta pantalla mostra la configuració bàsica del compte.
// Permet consultar el perfil real, editar dades personals, canviar la contrasenya
// i tancar la sessió de l’usuari autenticat.
@RoutePage()
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({
    super.key,
    this.onLogout,
  });

  // Aquesta funció permet connectar la pantalla amb la lògica real de logout.
  final Future<void> Function()? onLogout;

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

// Aquesta classe gestiona el comportament intern de la pantalla de configuració.
// S’encarrega de crear el controller, reaccionar als seus canvis
// i construir la interfície segons l’estat actual del perfil.
class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  // Aquest controlador concentra la càrrega del perfil,
  // la gestió d’errors, l’edició del compte i l’acció de tancar sessió.
  late final ProfileSettingsController controller;

  // Aquest mètode prepara el controller quan la pantalla es crea
  // i inicia la càrrega inicial de les dades del perfil.
  @override
  void initState() {
    super.initState();
    controller = ProfileSettingsController(
      logoutAction: widget.onLogout,
    )..addListener(_handleControllerChanges);

    controller.loadProfile();
  }

  // Aquest mètode escolta els canvis del controller i resol la navegació real
  // des de la vista, mantenint el controller desacoblat de la UI.
  void _handleControllerChanges() {
    if (!mounted) return;

    if (controller.destination == ProfileSettingsDestination.back) {
      controller.consumeNavigation();
      context.router.maybePop();
      return;
    }

    if (controller.destination == ProfileSettingsDestination.login) {
      controller.consumeNavigation();
      context.router.root.replaceAll([
        const LoginRoute(),
      ]);
      return;
    }

    // Aquest bloc mostra els errors puntuals a l’usuari
    // sense deixar-los persistint més temps del necessari a l’estat.
    if (controller.errorMessage != null) {
      final errorMessage = controller.errorMessage!;
      controller.consumeErrorMessage();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );
    }

    // Aquest bloc mostra les confirmacions de les operacions del perfil.
    // Després de mostrar-les, el missatge es consumeix per evitar repeticions.
    if (controller.successMessage != null) {
      final successMessage = controller.successMessage!;
      controller.consumeSuccessMessage();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
        ),
      );
    }
  }

  // Aquest mètode obre el formulari per editar les dades personals.
  // La pantalla resol la presentació visual i el controller manté l’estat del formulari.
  void _openEditProfileForm() {
    controller.prepareProfileForm();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return ProfileEditForm(
              firstNameController: controller.firstNameController,
              lastNameController: controller.lastNameController,
              showValidation: controller.showProfileValidation,
              isLoading: controller.isSavingProfile,
              onChanged: controller.onProfileFieldChanged,
              onCancel: () => Navigator.of(sheetContext).pop(),
              onSave: () async {
                final success = await controller.saveProfileChanges();

                if (success && sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
              },
            );
          },
        );
      },
    );
  }

  // Aquest mètode mostra les accions disponibles per gestionar la foto de perfil.
  // La pantalla només presenta les opcions; el controller executa la pujada o eliminació.
  Future<void> _openProfilePhotoActions() async {
    if (controller.isUpdatingProfilePhoto) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (_) {
        return ProfilePhotoActionsSheet(
          hasProfilePhoto: controller.hasProfilePhoto,
          isUpdatingProfilePhoto: controller.isUpdatingProfilePhoto,
          onSelectPhotoTap: controller.changeProfilePhoto,
          onDeletePhotoTap: controller.deleteProfilePhoto,
        );
      },
    );
  }

  // Aquest mètode obre el formulari per canviar la contrasenya.
  // Quan es tanca el formulari, es netegen els camps per no conservar dades sensibles.
  void _openPasswordForm() {
    controller.clearPasswordForm();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return ProfilePasswordForm(
              currentPasswordController: controller.currentPasswordController,
              newPasswordController: controller.newPasswordController,
              confirmPasswordController: controller.confirmPasswordController,
              showValidation: controller.showPasswordValidation,
              isLoading: controller.isChangingPassword,
              onChanged: controller.onPasswordFieldChanged,
              onCancel: () => Navigator.of(sheetContext).pop(),
              onSave: () async {
                final success = await controller.changePassword();

                if (success && sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
              },
            );
          },
        );
      },
    ).whenComplete(controller.clearPasswordForm);
  }

// Aquest mètode obre el formulari de desactivació del compte.
// La contrasenya es demana abans d’executar l’acció al backend.
  void _openDeleteAccountForm() {
    controller.clearDeleteAccountForm();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return ProfileDeleteAccountForm(
              passwordController: controller.deleteAccountPasswordController,
              showValidation: controller.showDeleteAccountValidation,
              isLoading: controller.isDeletingAccount,
              onChanged: controller.onDeleteAccountFieldChanged,
              onCancel: () => Navigator.of(sheetContext).pop(),
              onDelete: () async {
                final success = await controller.deleteAccount();

                if (success && sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
              },
            );
          },
        );
      },
    ).whenComplete(controller.clearDeleteAccountForm);
  }

  // Aquest mètode allibera el controller quan la pantalla deixa d’utilitzar-se.
  @override
  void dispose() {
    controller.removeListener(_handleControllerChanges);
    controller.dispose();
    super.dispose();
  }

  // Aquest mètode construeix la pantalla de configuració del perfil.
  // Organitza la capçalera, les opcions del compte i el botó de tancar sessió.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileSettingsTopBar(
                    onBackTap: controller.onBackTap,
                  ),
                  const SizedBox(height: 28),
                  ProfileSettingsHeader(
                    displayName: controller.displayName,
                    displayEmail: controller.displayEmail,
                    profilePhotoUrl: controller.profilePhotoUrl,
                    isUpdatingProfilePhoto: controller.isUpdatingProfilePhoto,
                  ),
                  const Spacer(),
                  const ProfileSettingsSectionTitle(),
                  const SizedBox(height: 14),
                  ProfileSettingsOptionsCard(
                    onChangeProfilePhotoTap: _openProfilePhotoActions,
                    onEditProfileTap: _openEditProfileForm,
                    onChangePasswordTap: _openPasswordForm,
                    onDeleteAccountTap: _openDeleteAccountForm,
                  ),
                  const SizedBox(height: 28),
                  ProfileSettingsLogoutButton(
                    isLoggingOut: controller.isLoggingOut,
                    onLogoutTap: controller.onLogoutTap,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
