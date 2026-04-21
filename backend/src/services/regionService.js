const RegionModel = require('../models/regionModel');

// Aquest servei centralitza la lògica de les comarques.
// Aquí es consulten les dades a través del model i es deixa preparat
// el punt d'extensió per si més endavant cal afegir-hi validacions o regles.
const RegionService = {

    // Aquest mètode retorna totes les comarques del sistema.
    // És rellevant perquè alimenta els filtres del catàleg de cims
    // i qualsevol altre lloc on calgui mostrar la divisió territorial.
    async getAll() {
        return RegionModel.findAll();
    },
};

module.exports = RegionService;
