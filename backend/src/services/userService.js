const UserModel = require('../models/userModel');

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
};

module.exports = UserService;