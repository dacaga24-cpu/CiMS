const rateLimit = require('express-rate-limit');

// Limitadors per protegir els endpoints sensibles davant d'intents massius
// o costosos (força bruta, abús del proveïdor de correu, creació massiva
// de comptes, força bruta de tokens).

// En desenvolupament desactivem alguns limitadors per no bloquejar-nos
// durant les proves locals. A producció (NODE_ENV=production a Cloud Run)
// es mantenen actius.
const skipOutsideProduction = () => process.env.NODE_ENV !== 'production';

// Login: força bruta de contrasenyes.
const loginRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many login attempts. Please try again later.' },
  skip: skipOutsideProduction,
});

// Forgot-password: cada petició consumeix una crida real a SendGrid.
const forgotPasswordRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 3,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many password reset requests. Please try again later.' },
});

// Register: evita creació massiva de comptes i enumeració d'emails via 409.
const registerRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many registration attempts. Please try again later.' },
});

// Reset-password: força bruta de tokens.
const resetPasswordRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many password reset attempts. Please try again later.' },
});

// Canvi de contrasenya: vector secundari de força bruta si el JWT queda
// compromès (cal saber la contrasenya actual, però el límit afegeix marge).
const changePasswordRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many password change attempts. Please try again later.' },
});

// Signed upload URLs: cada URL és barata però autoritza una pujada al bucket.
// Sense límit, un usuari podria demanar-ne milers i omplir el bucket d'orfes.
const signedUploadUrlRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many upload URL requests. Please try again later.' },
});

module.exports = {
  loginRateLimiter,
  forgotPasswordRateLimiter,
  registerRateLimiter,
  resetPasswordRateLimiter,
  changePasswordRateLimiter,
  signedUploadUrlRateLimiter,
};
