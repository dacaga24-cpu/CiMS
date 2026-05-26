const RegionService = require('../services/regionService');

// Aquest controlador gestiona les peticions relacionades amb les comarques.
// Delega la consulta al servei i retorna les dades en el format esperat pel frontend.
const RegionController = {

    // Retorna la llista completa de comarques disponibles.
    // Aquesta informació s’utilitza principalment per construir els filtres del catàleg de cims.
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