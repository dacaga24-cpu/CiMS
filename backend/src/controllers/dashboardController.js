const DashboardService = require('../services/dashboardService');

// Aquest controlador exposa l'endpoint únic de la pantalla del dashboard.
// La seva responsabilitat es limita a delegar al servei i retornar la
// resposta HTTP, ja que tota la lògica de composició viu a la capa de servei.
// L'identificador de l'usuari s'obté sempre de req.userId perquè el dashboard
// és sempre personal i mai s'ha de poder consultar el d'un altre usuari.
const DashboardController = {

  // Retorna el resum complet del dashboard per a l'usuari autenticat amb
  // codi 200. El servei sempre retorna un objecte amb tots els camps
  // definits, fins i tot per a usuaris nous (llistes buides, comptadors a
  // zero) perquè el frontend no hagi de fer comprovacions defensives.
  async getDashboard(req, res, next) {
    try {
      const dashboard = await DashboardService.getDashboard(req.userId);
      res.status(200).json(dashboard);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = DashboardController;
