const MonthlyChallengeService = require('../services/monthlyChallengeService');

// Aquest controlador exposa les rutes del repte mensual. La seva
// responsabilitat es limita a delegar al servei i retornar la resposta
// HTTP. L'identificador de l'usuari s'obté sempre de req.userId perquè
// el progrés del repte és sempre personal.
const MonthlyChallengeController = {

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
