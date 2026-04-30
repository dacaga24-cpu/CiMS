const StatsService = require('../services/statsService');

// Aquest controlador exposa les estadístiques personals de l'usuari
// autenticat. La seva responsabilitat es limita a delegar al servei i
// retornar la resposta HTTP, ja que tota la lògica de càlcul viu a la capa
// de servei. L'identificador de l'usuari s'obté sempre de req.userId perquè
// el client mai pugui demanar les estadístiques d'un altre usuari.
const StatsController = {

  // Retorna el resum bàsic de progrés de l'usuari autenticat amb codi 200.
  // El servei sempre retorna un objecte amb els tres comptadors definits, fins
  // i tot per a usuaris nous (en aquest cas, els tres valors són zero).
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
