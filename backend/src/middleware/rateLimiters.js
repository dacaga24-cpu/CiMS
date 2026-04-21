const rateLimit = require('express-rate-limit');

// Aquest fitxer centralitza els limitadors de peticions que protegeixen
// els endpoints sensibles del backend. La seva funció és evitar que un client
// pugui fer massa intents seguits contra operacions que són costoses o que
// poden ser utilitzades per atacs automàtics.

// Aquest limitador protegeix l'inici de sessió davant d'intents massius.
// Un nombre elevat d'intents consecutius des d'una mateixa IP acostuma a indicar
// un atac de força bruta contra contrasenyes, i aquest filtre el bloqueja
// abans que arribi a la lògica d'autenticació.
const loginRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minuts
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many login attempts. Please try again later.' },
});

// Aquest limitador protegeix la sol·licitud de recuperació de contrasenya.
// Cada petició genera un correu real via SendGrid i consumeix recursos del proveïdor,
// per això es restringeix el nombre d'intents des d'una mateixa IP dins d'un període curt.
const forgotPasswordRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minuts
  max: 3,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many password reset requests. Please try again later.' },
});

module.exports = {
  loginRateLimiter,
  forgotPasswordRateLimiter,
};
