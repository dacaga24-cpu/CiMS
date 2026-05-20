const UserModel = require('../models/userModel');
const StorageService = require('./storageService');
const { buildUserPathPattern } = require('./storageService');
const { badRequest } = require('../utils/validation');
const bcrypt = require('bcrypt');
const SALT_ROUNDS = 10;

// Aquest servei centralitza la lògica de negoci relacionada amb el perfil d'usuari.
// La seva funció és rebre les dades validades des del controlador, aplicar les
// regles necessàries i delegar les operacions de persistència al model.
//
// Per a la foto de perfil es comparteix el mateix patró que les fotos
// d'ascens (signed URL de pujada directa a GCS), però amb el namespace
// `profile-photos` per separar-les a nivell de bucket i de validació.

// Aquest helper esborra un blob del bucket sense aturar el flux si l'esborrat
// falla. S'usa quan se substitueix o s'elimina la foto de perfil: si GCS
// té un problema transitori, el path a la BD ja està actualitzat i no
// volem que l'usuari rebi un 500 per un blob orfe que es pot netejar
// posteriorment via lifecycle policy o un job de manteniment.
async function safeDeleteProfilePhotoBlob(storagePath, context = {}) {
  if (!storagePath) {
    return;
  }
  try {
    await StorageService.deleteObject(storagePath);
  } catch (err) {
    console.error(
      `[profilePhoto] orphan blob (userId=${context.userId ?? 'unknown'} path=${storagePath}):`,
      err
    );
  }
}

// Aquest helper construeix la representació pública del perfil que el
// frontend rep. La signed URL de descàrrega es genera aquí (no al model)
// perquè és una operació asíncrona i fora del SQL. S'omet el path cru de
// la resposta perquè el client mai ha de necessitar-lo: només interactua
// amb la URL de visualització, i no exposar-lo evita filtrar l'estructura
// interna del bucket ni l'esquema de noms.
//
// Si la signatura de la URL falla per un problema transitori de GCS, es
// degrada a profilePhotoUrl null i es loga l'error: la resposta del perfil
// sencera no ha de caure perquè la foto no es pugui mostrar puntualment,
// l'usuari ha de poder veure les seves dades bàsiques sempre.
async function composeProfileResponse(user) {
  let profilePhotoUrl = null;
  if (user.profile_photo_path) {
    try {
      profilePhotoUrl = await StorageService.generateSignedDownloadUrl(user.profile_photo_path);
    } catch (err) {
      console.error(
        `[profilePhoto] sign download URL failed (userId=${user.id} path=${user.profile_photo_path}):`,
        err
      );
    }
  }

  const { profile_photo_path, ...rest } = user;
  return { ...rest, profilePhotoUrl };
}

const UserService = {

  // Aquest mètode recupera el perfil complet de l'usuari autenticat amb
  // la signed URL de la foto ja generada perquè el client la pugui mostrar
  // sense haver de fer una segona crida.
  async getProfile(userId) {
    const user = await UserModel.findById(userId);

    if (!user) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }

    return composeProfileResponse(user);
  },

  // Aquest mètode actualitza el nom i el cognom de l'usuari autenticat.
  // Els noms es netegen d'espais superflus abans de guardar-los perquè
  // la base de dades no emmagatzemi variants idèntiques visualment però
  // diferents a nivell de text.
  // Un cop actualitzats, es retorna el perfil complet i actualitzat
  // perquè el client no hagi de fer una crida addicional per refrescar les dades.
  async updateProfile(userId, { firstName, lastName }) {
    const trimmedFirstName = firstName.trim();
    const trimmedLastName = lastName.trim();

    await UserModel.updateProfile(userId, {
      firstName: trimmedFirstName,
      lastName: trimmedLastName,
    });

    const user = await UserModel.findById(userId);
    return composeProfileResponse(user);
  },

  async changePassword(userId, { currentPassword, newPassword }) {
    const user = await UserModel.findByIdWithPassword(userId);

    if (!user) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }

    // Es verifica la contrasenya actual abans d'aplicar el canvi
    // per confirmar que qui fa la petició és el titular del compte.
    //
    // Important: retornem 400 (no 401) perquè aquest no és un cas de sessió
    // caducada — el token JWT del middleware ja l'ha validat. És un error
    // de validació del payload: la contrasenya introduïda no coincideix.
    // Si l'usem com a 401, el client interpreta sessió caducada i tanca
    // sessió quan en realitat només calia mostrar un missatge d'error.
    const isValid = await bcrypt.compare(currentPassword, user.password);
    if (!isValid) {
      const error = new Error('Current password is incorrect');
      error.statusCode = 400;
      throw error;
    }

    const hashedPassword = await bcrypt.hash(newPassword, SALT_ROUNDS);
    await UserModel.updatePassword(userId, hashedPassword);

    return { message: 'Password changed successfully' };
  },

  // Aquest mètode desactiva el compte de l'usuari autenticat.
  // Es demana la contrasenya actual per confirmar que l'acció
  // és voluntària i que ningú altre no pot fer-la en nom seu.
  //
  // Per decisió de producte, no s'esborren els blobs del bucket (foto
  // de perfil, fotos d'ascens) en aquest punt: el compte queda desactivat
  // (soft delete) però les dades es conserven per si l'usuari reactiva
  // el compte més endavant.
  async deleteAccount(userId, { password }) {
    const user = await UserModel.findByIdWithPassword(userId);

    if (!user) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }

    // Vegeu el comentari de changePassword: aquí també retornem 400 enlloc
    // de 401 perquè no és un error de sessió, és validació del payload.
    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      const error = new Error('Password is incorrect');
      error.statusCode = 400;
      throw error;
    }

    await UserModel.deactivateAccount(userId);
    return { message: 'Account deleted successfully' };
  },

  // Genera una signed URL de pujada per a la foto de perfil. Delega al
  // StorageService passant el namespace `profile-photos` per garantir
  // que el path generat queda separat del de les fotos d'ascens.
  async generateProfilePhotoUploadUrl(userId, { mimeType } = {}) {
    if (!mimeType || typeof mimeType !== 'string') {
      throw badRequest('Missing required field: mimeType');
    }
    return StorageService.generateSignedUploadUrl(userId, mimeType, 'profile-photos');
  },

  // Confirma una pujada de foto de perfil un cop el client l'ha completada
  // contra GCS. Valida el shape del path (UUID v4 + extensió de la
  // whitelist al namespace de l'usuari) i comprova que el blob existeix
  // realment al bucket abans d'actualitzar la BD. Si l'usuari ja tenia
  // una foto de perfil anterior, s'esborra del bucket per no acumular
  // orfes; aquest esborrat no és bloquejant (safeDeleteProfilePhotoBlob).
  //
  // Race condition coneguda: dos PUTs concurrents poden interleave
  // (read-old → update-new → delete-old) i deixar la BD apuntant a un
  // blob que el rival ja ha esborrat. La mitigació actual és el rate
  // limiter i la convenció d'una sola sessió activa per usuari; si en
  // el futur cal una garantia més estricta, s'hauria d'usar un UPDATE
  // condicional (WHERE profile_photo_path = ?) o una transacció
  // SELECT ... FOR UPDATE que serialitzi els PUTs.
  async setProfilePhoto(userId, { storagePath } = {}) {
    if (!storagePath || typeof storagePath !== 'string') {
      throw badRequest('Missing required field: storagePath');
    }
    const pattern = buildUserPathPattern(userId, 'profile-photos');
    if (!pattern.test(storagePath)) {
      throw badRequest(
        'Invalid storagePath: has an unexpected shape or does not belong to the user namespace'
      );
    }

    const exists = await StorageService.objectExists(storagePath);
    if (!exists) {
      throw badRequest(`Invalid storagePath: does not exist in storage (${storagePath})`);
    }

    const previous = await UserModel.findById(userId);
    if (!previous) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }
    const previousPath = previous.profile_photo_path;

    await UserModel.updateProfilePhoto(userId, storagePath);

    if (previousPath && previousPath !== storagePath) {
      await safeDeleteProfilePhotoBlob(previousPath, { userId });
    }

    // S'evita un segon findById construint la resposta a partir de la fila
    // que ja teníem llegida i sobreescrivint el camp acabat d'actualitzar.
    return composeProfileResponse({ ...previous, profile_photo_path: storagePath });
  },

  // Esborra la foto de perfil de l'usuari. Idempotent: si l'usuari no en
  // tenia, no fa res i retorna el perfil tal qual. Si en tenia, posa el
  // camp a NULL i intenta esborrar el blob del bucket.
  async removeProfilePhoto(userId) {
    const user = await UserModel.findById(userId);
    if (!user) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }
    const previousPath = user.profile_photo_path;

    // Camí ràpid quan no hi havia foto: no cal tocar BD ni bucket ni
    // tornar a llegir el perfil, ja que el resultat és el perfil tal
    // com l'acabem de carregar.
    if (!previousPath) {
      return composeProfileResponse(user);
    }

    await UserModel.updateProfilePhoto(userId, null);
    await safeDeleteProfilePhotoBlob(previousPath, { userId });

    // S'evita un segon findById construint la resposta a partir de la fila
    // que ja teníem llegida amb el camp actualitzat a null.
    return composeProfileResponse({ ...user, profile_photo_path: null });
  },
};

module.exports = UserService;
