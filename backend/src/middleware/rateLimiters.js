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

// Aquest limitador protegeix l'endpoint de registre. Sense límit, un atacant
// podria crear comptes massivament per saturar la base de dades o per enumerar
// quins correus existeixen al sistema combinant el registre amb els missatges
// d'error. Un sostre per IP redueix aquest risc sense afectar usuaris legítims.
const registerRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minuts
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many registration attempts. Please try again later.' },
});

// Aquest limitador protegeix la confirmació del restabliment de contrasenya.
// És un endpoint de validació de tokens i, sense límit, un atacant podria
// intentar endevinar tokens vàlids per força bruta. El filtre tanca aquesta
// via abans que arribi a la lògica de validació.
const resetPasswordRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minuts
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many password reset attempts. Please try again later.' },
});

// Aquest limitador protegeix el canvi de contrasenya des del perfil.
// Requereix conèixer la contrasenya actual, però un límit d'intents
// evita que es pugui usar com a vector de força bruta si el token JWT
// d'una sessió quedés compromès.
const changePasswordRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minuts
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many password change attempts. Please try again later.' },
});

// Aquest limitador protegeix la generació de signed URLs per pujar fotos
// d'ascensions. Cada signed URL és barata d'emetre però autoritza la
// pujada d'un objecte al bucket; sense límit, un usuari podria demanar-ne
// milers i omplir el bucket de blobs orfes (pujades que mai es confirmen
// amb un ascens). Un sostre per IP redueix aquest abús sense afectar els
// usuaris legítims, que típicament pujaran unes poques fotos per ascensió.
const signedUploadUrlRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minuts
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many upload URL requests. Please try again later.' },
});

// Aquest limitador protegeix els endpoints meteorològics. Cada petició que
// no troba resposta a la cache es tradueix en una crida a la Google Weather
// API, que consumeix quota i té un cost econòmic. Un sostre per IP evita
// que un client (legítim però mal programat, o malintencionat) pugui
// disparar centenars de crides en bucle i esgotar la quota compartida.
// El límit és prou generós perquè un usuari real que navegui per diversos
// cims i provi filtres no el toqui mai dins d'una sessió.
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
