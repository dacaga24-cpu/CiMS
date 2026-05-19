import 'package:cims/core/entity/user.dart';
import 'package:cims/core/entity/profile_photo_upload.dart';

// Aquest contracte agrupa les operacions relacionades amb el perfil d’usuari.
abstract class ProfileApiClient {
  // Aquest mètode recupera la informació del perfil de l’usuari
  // que té la sessió iniciada a l’aplicació.
  Future<User> getUserProfile();

  // Aquest mètode actualitza les dades bàsiques del perfil de l’usuari autenticat.
  // Retorna l’usuari actualitzat perquè la pantalla pugui refrescar la informació.
  Future<User> updateUserProfile({
    required String firstName,
    required String lastName,
  });

  // Aquest mètode permet canviar la contrasenya del compte autenticat.
  // Necessita la contrasenya actual i la nova per validar el canvi al backend.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  // Aquest mètode permet desactivar el compte de l’usuari autenticat.
  // Requereix la contrasenya actual per confirmar que l’acció és voluntària.
  Future<void> deleteAccount({
    required String password,
  });

  // Aquest mètode demana al backend una URL temporal per pujar una foto de perfil.
  Future<ProfilePhotoSignedUploadUrl> createProfilePhotoSignedUploadUrl({
    required String mimeType,
  });

  // Aquest mètode puja els bytes de la imatge directament a la URL temporal.
  Future<void> uploadProfilePhotoBytes({
    required String uploadUrl,
    required List<int> bytes,
    required Map<String, String> headers,
  });

  // Aquest mètode confirma al backend quina imatge pujada s’ha d’associar al perfil.
  Future<User> setProfilePhoto({
    required String storagePath,
  });

  // Aquest mètode elimina la foto de perfil actual de l’usuari autenticat.
  Future<User> deleteProfilePhoto();
}
