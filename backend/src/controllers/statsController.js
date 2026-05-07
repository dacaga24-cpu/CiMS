const StatsService = require('../services/statsService');

// Estadístiques personals. La lògica viu al servei; l'identificador d'usuari
// surt sempre de req.userId perquè mai es puguin demanar les estadístiques
// d'un altre usuari.
const StatsController = {

  // Resum de progrés. El servei sempre retorna tots els comptadors definits
  // (zeros per a usuaris nous).
  async getUserStats(req, res, next) {
    try {
      const stats = await StatsService.getUserStats(req.userId);
      res.status(200).json(stats);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = StatsController;
