const { validationResult } = require('express-validator');
const EstatCimModel = require('../models/estatCimModel');

class EstatController {
  // Obtenir tots els estats de l'usuari
  static async getMyStates(req, res) {
    try {
      const { estat } = req.query;
      const states = await EstatCimModel.findByUserId(req.user.id, estat);

      res.json({
        total: states.length,
        states
      });
    } catch (error) {
      console.error('Error obtenint estats:', error);
      res.status(500).json({
        error: 'Error obtenint els estats',
        message: error.message
      });
    }
  }

  // Obtenir favorits
  static async getFavorites(req, res) {
    try {
      const favorites = await EstatCimModel.getFavorites(req.user.id);

      res.json({
        total: favorites.length,
        favorites
      });
    } catch (error) {
      console.error('Error obtenint favorits:', error);
      res.status(500).json({
        error: 'Error obtenint favorits',
        message: error.message
      });
    }
  }

  // Obtenir completats
  static async getCompleted(req, res) {
    try {
      const completed = await EstatCimModel.getCompleted(req.user.id);

      res.json({
        total: completed.length,
        completed
      });
    } catch (error) {
      console.error('Error obtenint completats:', error);
      res.status(500).json({
        error: 'Error obtenint completats',
        message: error.message
      });
    }
  }

  // Obtenir planificats
  static async getPlanned(req, res) {
    try {
      const planned = await EstatCimModel.getPlanned(req.user.id);

      res.json({
        total: planned.length,
        planned
      });
    } catch (error) {
      console.error('Error obtenint planificats:', error);
      res.status(500).json({
        error: 'Error obtenint planificats',
        message: error.message
      });
    }
  }

  // Obtenir estat d'una ruta
  static async getRouteState(req, res) {
    try {
      const { routeId } = req.params;
      const state = await EstatCimModel.findByUserAndRoute(req.user.id, routeId);

      if (!state) {
        return res.status(404).json({
          error: 'Estat no trobat'
        });
      }

      res.json({ state });
    } catch (error) {
      console.error('Error obtenint estat:', error);
      res.status(500).json({
        error: 'Error obtenint l\'estat',
        message: error.message
      });
    }
  }

  // Actualitzar o crear estat
  static async upsertState(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { route_id, estat, notes } = req.body;

      // Validar estat
      const validStates = ['pendent', 'completat', 'favorit', 'planificat'];
      if (!validStates.includes(estat)) {
        return res.status(400).json({
          error: 'Estat no vàlid',
          message: `Els estats vàlids són: ${validStates.join(', ')}`
        });
      }

      const stateId = await EstatCimModel.upsert({
        user_id: req.user.id,
        route_id,
        estat,
        notes
      });

      const state = await EstatCimModel.findByUserAndRoute(req.user.id, route_id);

      res.json({
        message: 'Estat actualitzat correctament',
        state
      });
    } catch (error) {
      console.error('Error actualitzant estat:', error);
      res.status(500).json({
        error: 'Error actualitzant l\'estat',
        message: error.message
      });
    }
  }

  // Toggle favorit
  static async toggleFavorite(req, res) {
    try {
      const { routeId } = req.params;

      const isFavorite = await EstatCimModel.toggleFavorite(req.user.id, routeId);

      res.json({
        message: isFavorite ? 'Afegit a favorits' : 'Eliminat de favorits',
        isFavorite
      });
    } catch (error) {
      console.error('Error togglejant favorit:', error);
      res.status(500).json({
        error: 'Error modificant favorit',
        message: error.message
      });
    }
  }

  // Eliminar estat
  static async deleteState(req, res) {
    try {
      const { routeId } = req.params;

      const deleted = await EstatCimModel.delete(req.user.id, routeId);

      if (deleted) {
        res.json({
          message: 'Estat eliminat correctament'
        });
      } else {
        res.status(404).json({
          error: 'Estat no trobat'
        });
      }
    } catch (error) {
      console.error('Error eliminant estat:', error);
      res.status(500).json({
        error: 'Error eliminant l\'estat',
        message: error.message
      });
    }
  }

  // Obtenir estadístiques de l'usuari
  static async getMyStats(req, res) {
    try {
      const stats = await EstatCimModel.getUserStats(req.user.id);

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

module.exports = EstatController;
