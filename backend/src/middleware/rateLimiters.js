const rateLimit = require('express-rate-limit');

// Aquest fitxer centralitza els limitadors de peticions del backend.
// Protegeix les rutes sensibles davant d’abusos, intents massius o usos que poden consumir massa recursos.

// Aquest limitador protegeix l’inici de sessió.
// Redueix el risc d’intents repetits per endevinar contrasenyes.
const loginRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minuts
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many login attempts. Please try again later.' },
});

// Aquest limitador protegeix la sol·licitud de recuperació de contrasenya.
// Evita que es generin massa correus de recuperació en poc temps.
const forgotPasswordRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minuts
  max: 3,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many password reset requests. Please try again later.' },
});

// Aquest limitador protegeix el registre d’usuaris.
// Ajuda a evitar la creació massiva de comptes i redueix possibles abusos del sistema.
const registerRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minuts
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many registration attempts. Please try again later.' },
});

// Aquest limitador protegeix la confirmació del restabliment de contrasenya.
// Limita els intents de validació de tokens de recuperació.
const resetPasswordRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minuts
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many password reset attempts. Please try again later.' },
});

// Aquest limitador protegeix el canvi de contrasenya des del perfil.
// Redueix el risc d’intents repetits encara que una sessió estigui iniciada.
const changePasswordRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minuts
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many password change attempts. Please try again later.' },
});

// Aquest limitador protegeix la generació d’URLs temporals per pujar fotos.
// Evita un ús excessiu de l’emmagatzematge i la creació de pujades no confirmades.
const signedUploadUrlRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minuts
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many upload URL requests. Please try again later.' },
});

// Aquest limitador protegeix les peticions meteorològiques.
// Controla el consum de quota i evita crides excessives a serveis externs.
const weatherRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minuts
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many weather requests. Please try again later.' },
});

module.exports = {
  loginRateLimiter,
  forgotPasswordRateLimiter,
  registerRateLimiter,
  resetPasswordRateLimiter,
  changePasswordRateLimiter,
  signedUploadUrlRateLimiter,
  weatherRateLimiter,
};