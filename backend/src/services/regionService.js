const RegionModel = require('../models/regionModel');

// Lògica de comarques. Punt d'extensió per si més endavant cal afegir
// validacions o regles de negoci.
const RegionService = {

    // Totes les comarques per als filtres del catàleg.
    async getAll() {
        return RegionModel.findAll();
    },
};

module.exports = RegionService;
