const RegionService = require('../services/regionService');

// Aquest controlador gestiona les peticions relacionades amb les comarques.
// La seva funció és delegar la feina al servei i enviar la resposta HTTP
// amb el codi i el format adequats.
const RegionController = {

    // Aquest mètode retorna la llista completa de comarques disponibles.
    // S'utilitza sobretot per alimentar els filtres del catàleg de cims.
    async list(req, res, next) {
        try {
            const regions = await RegionService.getAll();
            res.status(200).json(regions);
        } catch (error) {
            next(error);
        }
    },
};

module.exports = RegionController;
