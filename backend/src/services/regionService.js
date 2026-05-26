const RegionModel = require('../models/regionModel');

// Aquest servei centralitza la gestió de les comarques.
// Manté separada la consulta de dades perquè el controlador no accedeixi directament al model.
const RegionService = {

    // Retorna totes les comarques disponibles al sistema.
    // Aquesta informació alimenta els filtres del catàleg i altres vistes amb criteri territorial.
    async getAll() {
        return RegionModel.findAll();
    },
};

module.exports = RegionService;