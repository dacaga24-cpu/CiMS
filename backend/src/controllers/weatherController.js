const WeatherService = require('../services/weatherService');

// Aquest controlador gestiona les peticions meteorològiques per cim de
// CiMS. La seva funció és llegir els paràmetres de la petició, delegar
// al servei i retornar la resposta HTTP en el format que el frontend
// espera. L'identificador de l'usuari s'obté de req.userId (poblat pel
// middleware d'autenticació) i només s'utilitza per a registres futurs
// o quotes per usuari; la previsió en si no depèn de qui consulta.
const WeatherController = {

  // Aquest mètode retorna la previsió diària d'un cim a partir del seu
  // identificador. El paràmetre days és opcional i es valida al servei
  // perquè la mateixa lògica de límits s'apliqui des de qualsevol
  // punt d'entrada.
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

  // Aquest mètode retorna la previsió horària d'un cim per a una data
  // concreta dins de l'horitzó disponible. La data es valida al servei i,
  // si la previsió ja no és disponible per a aquella data (cau fora del
  // rang de 240h), es retorna 404 perquè el client mostri el missatge
  // adequat.
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
