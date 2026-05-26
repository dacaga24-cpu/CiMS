const WeatherService = require('../services/weatherService');

// Aquest controlador gestiona les peticions meteorològiques associades als cims.
// Delega la consulta al servei i retorna la previsió en el format esperat pel frontend.
const WeatherController = {

  // Retorna la previsió diària d’un cim concret.
  // El nombre de dies és opcional i el servei valida els límits disponibles.
  async getPeakDaily(req, res, next) {
    try {
      const { peakId } = req.params;
      const { days } = req.query;

      const payload = await WeatherService.getDailyForecastForPeak(peakId, {
        days,
      });

      res.status(200).json(payload);
    } catch (error) {
      next(error);
    }
  },

  // Retorna la previsió horària d’un cim per a una data concreta.
  // Aquesta informació permet mostrar una previsió més detallada dins del rang disponible.
  async getPeakHourly(req, res, next) {
    try {
      const { peakId } = req.params;
      const { date } = req.query;

      const payload = await WeatherService.getHourlyForecastForPeak(
        peakId,
        date
      );

      res.status(200).json(payload);
    } catch (error) {
      next(error);
    }
  },
};

module.exports = WeatherController;