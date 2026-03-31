const { validationResult } = require('express-validator');
const AscensioModel = require('../models/ascensioModel');

class AscensioController {
  // Obtenir totes les ascensions de l'usuari autenticat
  static async getMyAscensions(req, res) {
    try {
      const ascensions = await AscensioModel.findByUserId(req.user.id);

      res.json({
        total: ascensions.length,
        ascensions
      });
    } catch (error) {
      console.error('Error obtenint ascensions:', error);
      res.status(500).json({
        error: 'Error obtenint les ascensions',
        message: error.message
      });
    }
  }

  // Obtenir ascensions d'una ruta específica
  static async getByRoute(req, res) {
    try {
      const { routeId } = req.params;
      const ascensions = await AscensioModel.findByRouteId(routeId);

      res.json({
        total: ascensions.length,
        ascensions
      });
    } catch (error) {
      console.error('Error obtenint ascensions de la ruta:', error);
      res.status(500).json({
        error: 'Error obtenint ascensions',
        message: error.message
      });
    }
  }

  // Obtenir una ascensió per ID
  static async getById(req, res) {
    try {
      const { id } = req.params;
      const ascensio = await AscensioModel.findById(id);

      if (!ascensio) {
        return res.status(404).json({
          error: 'Ascensió no trobada'
        });
      }

      // Verificar que l'ascensió pertany a l'usuari
      if (ascensio.user_id !== req.user.id) {
        return res.status(403).json({
          error: 'No tens permís per veure aquesta ascensió'
        });
      }

      res.json({ ascensio });
    } catch (error) {
      console.error('Error obtenint ascensió:', error);
      res.status(500).json({
        error: 'Error obtenint l\'ascensió',
        message: error.message
      });
    }
  }

  // Crear una nova ascensió
  static async create(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { route_id, data_ascensio, notes } = req.body;

      const ascensioId = await AscensioModel.create({
        user_id: req.user.id,
        route_id,
        data_ascensio,
        notes
      });

      const ascensio = await AscensioModel.findById(ascensioId);

      res.status(201).json({
        message: 'Ascensió registrada correctament',
        ascensio
      });
    } catch (error) {
      console.error('Error creant ascensió:', error);
      res.status(500).json({
        error: 'Error registrant l\'ascensió',
        message: error.message
      });
    }
  }

  // Actualitzar una ascensió
  static async update(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { id } = req.params;
      const { data_ascensio, notes } = req.body;

      const ascensio = await AscensioModel.findById(id);

      if (!ascensio) {
        return res.status(404).json({
          error: 'Ascensió no trobada'
        });
      }

      // Verificar que l'ascensió pertany a l'usuari
      if (ascensio.user_id !== req.user.id) {
        return res.status(403).json({
          error: 'No tens permís per modificar aquesta ascensió'
        });
      }

      const updated = await AscensioModel.update(id, {
        data_ascensio,
        notes
      });

      if (updated) {
        const updatedAscensio = await AscensioModel.findById(id);
        res.json({
          message: 'Ascensió actualitzada correctament',
          ascensio: updatedAscensio
        });
      } else {
        res.status(500).json({
          error: 'Error actualitzant l\'ascensió'
        });
      }
    } catch (error) {
      console.error('Error actualitzant ascensió:', error);
      res.status(500).json({
        error: 'Error actualitzant l\'ascensió',
        message: error.message
      });
    }
  }

  // Eliminar una ascensió
  static async delete(req, res) {
    try {
      const { id } = req.params;

      const ascensio = await AscensioModel.findById(id);

      if (!ascensio) {
        return res.status(404).json({
          error: 'Ascensió no trobada'
        });
      }

      // Verificar que l'ascensió pertany a l'usuari
      if (ascensio.user_id !== req.user.id) {
        return res.status(403).json({
          error: 'No tens permís per eliminar aquesta ascensió'
        });
      }

      const deleted = await AscensioModel.delete(id);

      if (deleted) {
        res.json({
          message: 'Ascensió eliminada correctament'
        });
      } else {
        res.status(500).json({
          error: 'Error eliminant l\'ascensió'
        });
      }
    } catch (error) {
      console.error('Error eliminant ascensió:', error);
      res.status(500).json({
        error: 'Error eliminant l\'ascensió',
        message: error.message
      });
    }
  }

  // Obtenir estadístiques de l'usuari
  static async getMyStats(req, res) {
    try {
      const stats = await AscensioModel.getUserStats(req.user.id);

      res.json({ stats });
    } catch (error) {
      console.error('Error obtenint estadístiques:', error);
      res.status(500).json({
        error: 'Error obtenint estadístiques',
        message: error.message
      });
    }
  }
}

module.exports = AscensioController;
