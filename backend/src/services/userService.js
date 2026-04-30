const UserModel = require('../models/userModel');
const bcrypt = require('bcrypt');
const SALT_ROUNDS = 10;

// Aquest servei centralitza la lògica de negoci relacionada amb el perfil d'usuari.
// La seva funció és rebre les dades validades des del controlador, aplicar les
// regles necessàries i delegar les operacions de persistència al model.
const UserService = {

  // Aquest mètode recupera el perfil complet de l'usuari autenticat.
  // Si l'identificador no correspon a cap compte existent, llança un error
  // perquè el controlador el pugui transformar en una resposta 404 coherent.
  async getProfile(userId) {
    const user = await UserModel.findById(userId);

    if (!user) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }

    return user;
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

    return UserModel.findById(userId);
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
    const isValid = await bcrypt.compare(currentPassword, user.password);
    if (!isValid) {
      const error = new Error('Current password is incorrect');
      error.statusCode = 401;
      throw error;
    }

    const hashedPassword = await bcrypt.hash(newPassword, SALT_ROUNDS);
    await UserModel.updatePassword(userId, hashedPassword);

    return { message: 'Password changed successfully' };
  },

  // Aquest mètode desactiva el compte de l'usuari autenticat.
  // Es demana la contrasenya actual per confirmar que l'acció
  // és voluntària i que ningú altre no pot fer-la en nom seu.
  async deleteAccount(userId, { password }) {
    const user = await UserModel.findByIdWithPassword(userId);

    if (!user) {
      const error = new Error('User not found');
      error.statusCode = 404;
      throw error;
    }

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      const error = new Error('Password is incorrect');
      error.statusCode = 401;
      throw error;
    }

    await UserModel.deactivateAccount(userId);
    return { message: 'Account deleted successfully' };
  },
};

module.exports = UserService;