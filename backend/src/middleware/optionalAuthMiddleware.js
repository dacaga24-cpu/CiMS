// Aquest middleware llegeix el token JWT si la petició en porta un, però
// no l'exigeix. La idea és habilitar comportament enriquit (per exemple,
// filtrar el catàleg per l'estat personal de l'usuari) sense trencar
// l'accés públic a les mateixes rutes quan no hi ha sessió.
//
// Difereix d'`authMiddleware.js` en el tractament dels errors: si manca el
// header, està malformat o el token no és vàlid, l'`optionalAuth` continua
// la petició amb `req.userId = undefined` en lloc de respondre 401. D'aquesta
// manera els controladors decideixen què fer amb la falta d'identitat
// (típicament: ignorar el filtre que la requereix) sense canviar el codi
// de resposta — així evitem filtrar via 200 vs 401 si l'usuari té sessió.
const jwt = require('jsonwebtoken');

const optionalAuthMiddleware = (req, res, next) => {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    // Si el secret no està configurat tractem com a error 500 igual que
    // l'authMiddleware estricte: és un problema d'infraestructura, no un
    // intent d'accés legítim.
    const error = new Error('JWT_SECRET is not defined in environment variables');
    error.statusCode = 500;
    return next(error);
  }

  const authHeader = req.headers.authorization;
  if (!authHeader) {
    return next();
  }

  const parts = authHeader.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer' || !parts[1]) {
    // Header present però malformat: l'ignorem en silenci enlloc de fallar.
    return next();
  }

  try {
    const decoded = jwt.verify(parts[1], secret);
    // Validem que el claim `userId` sigui un enter positiu. Sense això,
    // un token signat però amb un userId inesperat (`null`, una string,
    // 0, negatiu...) generaria queries amb un user_id invàlid i estats
    // sempre buits sense que l'error fos visible.
    if (Number.isInteger(decoded.userId) && decoded.userId > 0) {
      req.userId = decoded.userId;
    }
  } catch (error) {
    // Només degradem silenciosament els errors propis de JWT (token
    // caducat, signatura invàlida, encara no vàlid). Qualsevol altre
    // tipus d'error (TypeError, bugs interns) ha de propagar-se cap a
    // l'`errorHandler` perquè quedi visible als logs i no s'amagui
    // darrere del comportament "opcional" d'aquest middleware.
    const isJwtError =
      error.name === 'JsonWebTokenError' ||
      error.name === 'TokenExpiredError' ||
      error.name === 'NotBeforeError';
    if (!isJwtError) {
      return next(error);
    }
  }

  next();
};

module.exports = optionalAuthMiddleware;
