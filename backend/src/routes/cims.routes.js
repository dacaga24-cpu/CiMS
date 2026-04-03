const express = require('express');
const { body } = require('express-validator');
const CimController = require('../controllers/cimController');
const { authMiddleware, optionalAuth } = require('../middleware/auth');

const router = express.Router();

// Validacions per crear/actualitzar cim
const cimValidation = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('El nom és obligatori')
    .isLength({ max: 255 })
    .withMessage('El nom no pot tenir més de 255 caràcters'),
  body('description')
    .optional()
    .trim(),
  body('distance')
    .isFloat({ min: 0 })
    .withMessage('La distància ha de ser un número positiu'),
  body('duration')
    .isInt({ min: 0 })
    .withMessage('La durada ha de ser un número enter positiu'),
  body('difficulty')
    .isIn(['fácil', 'media', 'difícil'])
    .withMessage('La dificultat ha de ser: fácil, media o difícil'),
  body('latitude')
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage('Latitud no vàlida'),
  body('longitude')
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage('Longitud no vàlida')
];

// @route   GET /api/cims
// @desc    Obtenir tots els cims (amb filtres opcionals: ?difficulty=media&search=montseny)
// @access  Public (amb autenticació opcional)
router.get('/', optionalAuth, CimController.getAll);

// @route   GET /api/cims/stats
// @desc    Obtenir estadístiques dels cims
// @access  Public
router.get('/stats', CimController.getStats);

// @route   GET /api/cims/:id
// @desc    Obtenir un cim per ID
// @access  Public (amb autenticació opcional)
router.get('/:id', optionalAuth, CimController.getById);

// @route   POST /api/cims
// @desc    Crear un nou cim
// @access  Private (requereix autenticació)
router.post('/', authMiddleware, cimValidation, CimController.create);

// @route   PUT /api/cims/:id
// @desc    Actualitzar un cim
// @access  Private (requereix autenticació)
router.put('/:id', authMiddleware, cimValidation, CimController.update);

// @route   DELETE /api/cims/:id
// @desc    Eliminar un cim
// @access  Private (requereix autenticació)
router.delete('/:id', authMiddleware, CimController.delete);

module.exports = router;
