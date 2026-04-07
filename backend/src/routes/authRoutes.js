// Framework and router
const express = require('express');
const router = express.Router();

// Redirection for /register
const AuthController = require('../controllers/authController');
router.post('/register', AuthController.register);

module.exports = router;