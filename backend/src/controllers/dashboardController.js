const DashboardService = require('../services/dashboardService');

// Aquest controlador gestiona la petició principal del dashboard.
// Delega la composició de dades al servei i retorna el resum personal de l’usuari autenticat.
const DashboardController = {

  // Retorna el resum complet del dashboard de l’usuari.
  // El servei prepara una resposta estable perquè el frontend pugui mostrar comptadors i llistes sense comprovacions addicionals.
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