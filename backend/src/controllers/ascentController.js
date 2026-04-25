const AscentService = require('../services/ascentService');

// Aquest controlador gestiona les peticions HTTP relacionades amb les
// ascensions registrades pels usuaris. La seva funció és llegir els
// paràmetres de la petició, delegar la lògica al servei i enviar la resposta
// amb el codi HTTP adequat. L'identificador de l'usuari s'obté sempre de
// req.userId (poblat pel authMiddleware a partir del JWT) i mai del cos o
// la URL, per evitar que un client pugui actuar en nom d'un altre.
const AscentController = {

  // Retorna totes les ascensions de l'usuari autenticat.
  // Sempre 200, amb llista buida si l'usuari encara no n'ha registrat cap.
  async getByUser(req, res, next) {
    try {
      const ascents = await AscentService.getByUser(req.userId);
      res.status(200).json(ascents);
    } catch (error) {
      next(error);
    }
  },

  // Retorna les ascensions de l'usuari autenticat sobre un cim concret.
  // El peakId arriba per la URL i es valida al servei.
  async getByUserAndPeak(req, res, next) {
    try {
      const ascents = await AscentService.getByUserAndPeak(
        req.userId,
        req.params.peakId,
      );
      res.status(200).json(ascents);
    } catch (error) {
      next(error);
    }
  },

  // Crea una nova ascensió. Respon 201 amb el registre creat o un 4xx si la
  // validació falla. Els errors de FK (peak inexistent) també es propaguen
  // com a 404 des del model.
  async create(req, res, next) {
    try {
      const { peakId, ascentDate, notes } = req.body || {};

      const ascent = await AscentService.create(req.userId, {
        peakId,
        ascentDate,
        notes,
      });

      res.status(201).json(ascent);
    } catch (error) {
      next(error);
    }
  },

  // Actualitza una ascensió existent. Respon 200 amb el registre resultant.
  // Si l'ascensió no existeix o no pertany a l'usuari autenticat, respon 404.
  async update(req, res, next) {
    try {
      const { peakId, ascentDate, notes } = req.body || {};

      const ascent = await AscentService.update(
        req.userId,
        req.params.ascentId,
        { peakId, ascentDate, notes },
      );

      res.status(200).json(ascent);
    } catch (error) {
      next(error);
    }
  },

  // Elimina una ascensió. Respon 204 sense cos si tot va bé,
  // o 404 si l'ascensió no existeix o és d'un altre usuari.
  async remove(req, res, next) {
    try {
      await AscentService.remove(req.userId, req.params.ascentId);
      res.status(204).send();
    } catch (error) {
      next(error);
    }
  },
};

module.exports = AscentController;
