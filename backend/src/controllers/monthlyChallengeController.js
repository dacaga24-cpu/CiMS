const MonthlyChallengeService = require('../services/monthlyChallengeService');

// Aquest controlador gestiona les peticions relacionades amb el repte mensual.
// Delega la lògica al servei i retorna el progrés personal de l’usuari autenticat.
const MonthlyChallengeController = {

  // Retorna el repte mensual actual de l’usuari.
  // Aquesta informació permet mostrar al frontend l’estat del repte i el progrés assolit.
  async getCurrent(req, res, next) {
    try {
      const challenge = await MonthlyChallengeService.getCurrentChallengeForUser(req.userId);
      res.status(200).json(challenge);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = MonthlyChallengeController;