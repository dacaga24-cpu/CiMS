const DashboardService = require('../services/dashboardService');

// Endpoint únic del dashboard. La composició viu al servei; l'identificador
// d'usuari surt sempre de req.userId perquè el dashboard és sempre personal.
const DashboardController = {

  // Resum complet per a l'usuari autenticat. El servei sempre retorna tots
  // els camps definits, fins i tot per a usuaris nous, perquè el frontend
  // no faci comprovacions defensives.
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
