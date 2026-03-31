const { validationResult } = require('express-validator');
const CimModel = require('../models/cimModel');

class CimController {
  // Obtenir tots els cims
  static async getAll(req, res) {
    try {
      const { difficulty, search } = req.query;

      let cims;

      if (search) {
        cims = await CimModel.search(search);
      } else if (difficulty) {
        cims = await CimModel.findByDifficulty(difficulty);
      } else {
        cims = await CimModel.findAll();
      }

      res.json({
        total: cims.length,
        cims
      });
    } catch (error) {
      console.error('Error obtenint cims:', error);
      res.status(500).json({
        error: 'Error obtenint els cims',
        message: error.message
      });
    }
  }

  // Obtenir un cim per ID
  static async getById(req, res) {
    try {
      const { id } = req.params;
      const cim = await CimModel.findById(id);

      if (!cim) {
        return res.status(404).json({
          error: 'Cim no trobat'
        });
      }

      res.json({ cim });
    } catch (error) {
      console.error('Error obtenint cim:', error);
      res.status(500).json({
        error: 'Error obtenint el cim',
        message: error.message
      });
    }
  }

  // Crear un nou cim
  static async create(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { name, description, distance, duration, difficulty, latitude, longitude } = req.body;

      const cimId = await CimModel.create({
        name,
        description,
        distance,
        duration,
        difficulty,
        latitude,
        longitude
      });

      const cim = await CimModel.findById(cimId);

      res.status(201).json({
        message: 'Cim creat correctament',
        cim
      });
    } catch (error) {
      console.error('Error creant cim:', error);
      res.status(500).json({
        error: 'Error creant el cim',
        message: error.message
      });
    }
  }

  // Actualitzar un cim
  static async update(req, res) {
    try {
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        return res.status(400).json({ errors: errors.array() });
      }

      const { id } = req.params;
      const { name, description, distance, duration, difficulty, latitude, longitude } = req.body;

      const exists = await CimModel.findById(id);
      if (!exists) {
        return res.status(404).json({
          error: 'Cim no trobat'
        });
      }

      const updated = await CimModel.update(id, {
        name,
        description,
        distance,
        duration,
        difficulty,
        latitude,
        longitude
      });

      if (updated) {
        const cim = await CimModel.findById(id);
        res.json({
          message: 'Cim actualitzat correctament',
          cim
        });
      } else {
        res.status(500).json({
          error: 'Error actualitzant el cim'
        });
      }
    } catch (error) {
      console.error('Error actualitzant cim:', error);
      res.status(500).json({
        error: 'Error actualitzant el cim',
        message: error.message
      });
    }
  }

  // Eliminar un cim
  static async delete(req, res) {
    try {
      const { id } = req.params;

      const exists = await CimModel.findById(id);
      if (!exists) {
        return res.status(404).json({
          error: 'Cim no trobat'
        });
      }

      const deleted = await CimModel.delete(id);

      if (deleted) {
        res.json({
          message: 'Cim eliminat correctament'
        });
      } else {
        res.status(500).json({
          error: 'Error eliminant el cim'
        });
      }
    } catch (error) {
      console.error('Error eliminant cim:', error);
      res.status(500).json({
        error: 'Error eliminant el cim',
        message: error.message
      });
    }
  }

  // Obtenir estadístiques
  static async getStats(req, res) {
    try {
      const stats = await CimModel.getStats();
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

module.exports = CimController;
