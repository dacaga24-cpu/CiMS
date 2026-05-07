const MonthlyChallengeService = require('../services/monthlyChallengeService');

// Repte mensual. L'identificador d'usuari surt sempre de req.userId perquè
// el progrés és sempre personal.
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
