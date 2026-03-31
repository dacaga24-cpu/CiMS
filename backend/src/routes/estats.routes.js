const express = require('express');
const { body } = require('express-validator');
const EstatController = require('../controllers/estatController');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// Totes les rutes d'estats requereixen autenticació
router.use(authMiddleware);

// Validacions per crear/actualitzar estat
const estatValidation = [
  body('route_id')
    .isInt({ min: 1 })
    .withMessage('ID de ruta no vàlid'),
  body('estat')
    .isIn(['pendent', 'completat', 'favorit', 'planificat'])
    .withMessage('Estat no vàlid (pendent, completat, favorit, planificat)'),
  body('notes')
    .optional()
    .trim()
];

// @route   GET /api/estats
// @desc    Obtenir tots els estats de l'usuari (amb filtre opcional: ?estat=favorit)
// @access  Private
router.get('/', EstatController.getMyStates);

// @route   GET /api/estats/stats
// @desc    Obtenir estadístiques dels estats de l'usuari
// @access  Private
router.get('/stats', EstatController.getMyStats);

// @route   GET /api/estats/favorites
// @desc    Obtenir favorits de l'usuari
// @access  Private
router.get('/favorites', EstatController.getFavorites);

// @route   GET /api/estats/completed
// @desc    Obtenir rutes completades
// @access  Private
router.get('/completed', EstatController.getCompleted);

// @route   GET /api/estats/planned
// @desc    Obtenir rutes planificades
// @access  Private
router.get('/planned', EstatController.getPlanned);

// @route   GET /api/estats/route/:routeId
// @desc    Obtenir estat d'una ruta específica
// @access  Private
router.get('/route/:routeId', EstatController.getRouteState);

// @route   POST /api/estats
// @desc    Crear o actualitzar estat d'una ruta
// @access  Private
router.post('/', estatValidation, EstatController.upsertState);

// @route   POST /api/estats/favorite/:routeId
// @desc    Toggle favorit d'una ruta
// @access  Private
router.post('/favorite/:routeId', EstatController.toggleFavorite);

// @route   DELETE /api/estats/route/:routeId
// @desc    Eliminar estat d'una ruta
// @access  Private
router.delete('/route/:routeId', EstatController.deleteState);

module.exports = router;
