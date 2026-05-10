const StatsService = require('../services/statsService');

// Aquest controlador exposa les estadístiques personals de l'usuari autenticat.
// La seva responsabilitat és llegir els paràmetres de la petició, delegar el
// càlcul al servei i retornar una resposta HTTP estable.
const StatsController = {

  // Retorna el resum de progrés de l'usuari autenticat.
  // El paràmetre range permet ajustar les mètriques variables de la pantalla,
  // com els metres acumulats, sense crear endpoints separats.
  async getUserStats(req, res, next) {
    try {
      const stats = await StatsService.getUserStats(
        req.userId,
        req.query.range,
      );

      res.status(200).json(stats);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = StatsController;