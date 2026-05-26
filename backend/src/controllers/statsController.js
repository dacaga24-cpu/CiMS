const StatsService = require('../services/statsService');

// Aquest controlador gestiona les peticions relacionades amb les estadístiques personals.
// Delega el càlcul al servei i retorna una resposta preparada per mostrar el progrés de l’usuari.
const StatsController = {

  // Retorna el resum de progrés de l’usuari autenticat.
  // El rang permet ajustar algunes mètriques de la pantalla sense crear noves rutes.
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