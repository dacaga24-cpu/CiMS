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
  }
};