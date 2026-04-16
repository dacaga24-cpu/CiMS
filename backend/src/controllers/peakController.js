const PeakService = require('../services/peakService');

function badRequest(message) {
const error = new Error(message);
error.statusCode = 400;
return error;
}

const PeakController = {

    async list(req, res, next) {
        try {
        const { regionId, minAltitude, maxAltitude, search } = req.query;

        const peaks = await PeakService.getAll({
            regionId,
            minAltitude,
            maxAltitude,
            search,
        });

        res.status(200).json(peaks);
        } catch (error) {
        next(error);
        }
    },

    async getById(req, res, next) {
      try {
        const id = Number(req.params.id);
        if (!Number.isInteger(id) || id <= 0) {
          throw badRequest('Invalid peak id');
        }

        const peak = await PeakService.getById(id);
        res.status(200).json(peak);
      } catch (error) {
        next(error);
      }
    },  
};

module.exports = PeakController;