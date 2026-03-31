const express = require('express');
const { body } = require('express-validator');
const AscensioController = require('../controllers/ascensioController');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// Totes les rutes d'ascensions requereixen autenticació
router.use(authMiddleware);

// Validacions per crear/actualitzar ascensió
const ascensioValidation = [
  body('route_id')
    .isInt({ min: 1 })
    .withMessage('ID de ruta no vàlid'),
  body('data_ascensio')
    .isISO8601()
    .withMessage('Data no vàlida (format: YYYY-MM-DD)'),
  body('notes')
    .optional()
    .trim()
];

const updateAscensioValidation = [
  body('data_ascensio')
    .isISO8601()
    .withMessage('Data no vàlida (format: YYYY-MM-DD)'),
  body('notes')
    .optional()
    .trim()
];

// @route   GET /api/ascensions
// @desc    Obtenir totes les ascensions de l'usuari autenticat
// @access  Private
router.get('/', AscensioController.getMyAscensions);

// @route   GET /api/ascensions/stats
// @desc    Obtenir estadístiques de les ascensions de l'usuari
// @access  Private
router.get('/stats', AscensioController.getMyStats);

// @route   GET /api/ascensions/route/:routeId
// @desc    Obtenir ascensions d'una ruta específica
// @access  Private
router.get('/route/:routeId', AscensioController.getByRoute);

// @route   GET /api/ascensions/:id
// @desc    Obtenir una ascensió per ID
// @access  Private
router.get('/:id', AscensioController.getById);

// @route   POST /api/ascensions
// @desc    Crear una nova ascensió
// @access  Private
router.post('/', ascensioValidation, AscensioController.create);

// @route   PUT /api/ascensions/:id
// @desc    Actualitzar una ascensió
// @access  Private
router.put('/:id', updateAscensioValidation, AscensioController.update);

// @route   DELETE /api/ascensions/:id
// @desc    Eliminar una ascensió
// @access  Private
router.delete('/:id', AscensioController.delete);

module.exports = router;
